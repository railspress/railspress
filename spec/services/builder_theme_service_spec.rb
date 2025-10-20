require 'rails_helper'

RSpec.describe BuilderThemeService, type: :service do
  let(:user) { create(:user) }
  let(:builder_theme) { create(:builder_theme, user: user) }
  let(:service) { BuilderThemeService.new(builder_theme) }

  describe '#initialize' do
    it 'sets the builder theme' do
      expect(service.builder_theme).to eq(builder_theme)
    end
  end

  describe '#apply_snapshot_to_frontend' do
    let(:snapshot) { create(:builder_theme_snapshot, builder_theme: builder_theme) }

    before do
      allow(builder_theme).to receive(:published?).and_return(true)
      allow(builder_theme.builder_theme_snapshots).to receive(:last).and_return(snapshot)
    end

    it 'applies snapshot to frontend successfully' do
      allow(service).to receive(:update_active_theme_settings)
      allow(service).to receive(:clear_theme_caches)
      allow(service).to receive(:notify_frontend_update)

      result = service.apply_snapshot_to_frontend

      expect(result).to be true
    end

    it 'returns false when theme is not published' do
      allow(builder_theme).to receive(:published?).and_return(false)

      result = service.apply_snapshot_to_frontend

      expect(result).to be false
    end

    it 'returns false when no snapshot exists' do
      allow(builder_theme.builder_theme_snapshots).to receive(:last).and_return(nil)

      result = service.apply_snapshot_to_frontend

      expect(result).to be false
    end
  end

  describe '#create_version_from_theme' do
    let(:theme_name) { 'test_theme' }
    let(:base_version) { create(:builder_theme, theme_name: theme_name) }

    before do
      allow(BuilderTheme).to receive(:current_for_theme).with(theme_name).and_return(base_version)
      allow(BuilderTheme).to receive(:create_version).and_return(builder_theme)
    end

    it 'creates version from existing theme' do
      allow(service).to receive(:copy_files_from_version)

      result = service.create_version_from_theme(theme_name, user, 'New version')

      expect(result).to eq(builder_theme)
    end

    it 'copies files from base version when available' do
      expect(service).to receive(:copy_files_from_version).with(base_version, builder_theme)

      service.create_version_from_theme(theme_name, user)
    end

    it 'copies files from theme directory when no base version' do
      allow(BuilderTheme).to receive(:current_for_theme).with(theme_name).and_return(nil)
      expect(service).to receive(:copy_files_from_theme_directory).with(theme_name, builder_theme)

      service.create_version_from_theme(theme_name, user)
    end
  end

  describe '#export_theme_package' do
    let(:theme_file) { create(:builder_theme_file, builder_theme: builder_theme, path: 'templates/index.liquid', content: '<h1>Hello</h1>') }

    before do
      allow(builder_theme).to receive(:published?).and_return(true)
      allow(builder_theme.builder_theme_files).to receive(:each).and_yield(theme_file)
    end

    it 'exports theme package successfully' do
      allow(FileUtils).to receive(:mkdir_p)
      allow(File).to receive(:write)
      allow(File).to receive(:exist?).and_return(true)
      allow(system).to receive(:call).and_return(true)
      allow(FileUtils).to receive(:rm_rf)

      result = service.export_theme_package

      expect(result).to be_present
    end

    it 'returns nil when theme is not published' do
      allow(builder_theme).to receive(:published?).and_return(false)

      result = service.export_theme_package

      expect(result).to be_nil
    end

    it 'handles export errors gracefully' do
      allow(FileUtils).to receive(:mkdir_p).and_raise(StandardError.new('Permission denied'))

      result = service.export_theme_package

      expect(result).to be_nil
    end
  end

  describe '.import_theme_package' do
    let(:zip_file) { double('zip_file', path: '/tmp/test.zip') }
    let(:temp_dir) { Rails.root.join('tmp', 'theme_imports', 'test') }

    before do
      allow(FileUtils).to receive(:mkdir_p)
      allow(Kernel).to receive(:system).and_return(true)
      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:read).and_return('{"name": "Test Theme"}')
      allow(BuilderTheme).to receive(:create_version).and_return(builder_theme)
      allow(FileUtils).to receive(:rm_rf)
    end

    it 'imports theme package successfully' do
      allow(BuilderThemeService).to receive(:copy_files_from_directory)

      result = BuilderThemeService.import_theme_package(zip_file, user, 'Test Theme')

      expect(result).to eq(builder_theme)
    end

    it 'uses theme name from metadata when not provided' do
      allow(BuilderThemeService).to receive(:copy_files_from_directory)

      result = BuilderThemeService.import_theme_package(zip_file, user)

      expect(result).to eq(builder_theme)
    end

    it 'handles import errors gracefully' do
      allow(system).to receive(:call).and_return(false)

      result = BuilderThemeService.import_theme_package(zip_file, user)

      expect(result).to be_nil
    end
  end

  describe '#validate_theme_structure' do
    let(:valid_json_file) { create(:builder_theme_file, builder_theme: builder_theme, path: 'templates/index.json', content: '{"order": ["header"]}') }
    let(:invalid_json_file) { create(:builder_theme_file, builder_theme: builder_theme, path: 'templates/invalid.json', content: 'invalid json') }
    let(:liquid_file) { create(:builder_theme_file, builder_theme: builder_theme, path: 'sections/header.liquid', content: '<header>Header</header>') }
    let(:empty_liquid_file) { create(:builder_theme_file, builder_theme: builder_theme, path: 'sections/empty.liquid', content: '') }

    before do
      allow(builder_theme).to receive(:get_file).and_return('content')
      allow(builder_theme.builder_theme_files).to receive(:json_files).and_return([valid_json_file, invalid_json_file])
      allow(builder_theme.builder_theme_files).to receive(:liquid_files).and_return([liquid_file, empty_liquid_file])
    end

    it 'validates theme structure successfully' do
      errors = service.validate_theme_structure

      expect(errors).to be_an(Array)
      expect(errors).to include('Invalid JSON in templates/invalid.json')
      expect(errors).to include('Empty Liquid file: sections/empty.liquid')
    end

    it 'checks for required files' do
      allow(builder_theme).to receive(:get_file).with('templates/index.json').and_return('content')
      allow(builder_theme).to receive(:get_file).with('layout/theme.liquid').and_return(nil)

      errors = service.validate_theme_structure

      expect(errors).to include('Missing required file: layout/theme.liquid')
    end
  end

  describe 'private methods' do
    describe '#update_active_theme_settings' do
      let(:active_theme) { create(:theme, active: true) }
      let(:snapshot) { create(:builder_theme_snapshot, settings: { 'color' => 'blue' }) }

      before do
        allow(Theme).to receive(:active).and_return(double(first: active_theme))
        allow(active_theme).to receive(:settings).and_return({ 'font' => 'Arial' })
        allow(active_theme).to receive(:update!)
        allow(Rails.cache).to receive(:write)
      end

      it 'updates active theme settings' do
        service.send(:update_active_theme_settings, snapshot)

        expect(active_theme).to have_received(:update!).with(hash_including(settings: { 'font' => 'Arial', 'color' => 'blue' }))
        expect(Rails.cache).to have_received(:write).with("active_theme_snapshot_#{active_theme.name}", snapshot.id, expires_in: 1.week)
      end
    end

    describe '#clear_theme_caches' do
      it 'clears theme caches' do
        allow(ActionView::LookupContext::DetailsKey).to receive(:clear)
        allow(Rails.cache).to receive(:delete_matched)
        allow(Rails.application.config).to receive(:respond_to?).with(:assets).and_return(true)
        allow(Rails.application.config.assets).to receive(:version=)

        service.send(:clear_theme_caches)

        expect(ActionView::LookupContext::DetailsKey).to have_received(:clear)
        expect(Rails.cache).to have_received(:delete_matched).with('theme_*')
        expect(Rails.application.config.assets).to have_received(:version=)
      end
    end

    describe '#notify_frontend_update' do
      it 'broadcasts theme update notification' do
        allow(ActionCable.server).to receive(:broadcast)

        service.send(:notify_frontend_update)

        expect(ActionCable.server).to have_received(:broadcast).with(
          'theme_updates',
          hash_including(
            type: 'theme_updated',
            theme_name: builder_theme.theme_name,
            timestamp: be_a(Integer)
          )
        )
      end
    end

    describe '#copy_files_from_version' do
      let(:source_version) { create(:builder_theme) }
      let(:target_version) { create(:builder_theme) }
      let(:source_file) { create(:builder_theme_file, builder_theme: source_version, path: 'test.liquid', content: 'content') }

      before do
        allow(source_version.builder_theme_files).to receive(:each).and_yield(source_file)
        allow(target_version.builder_theme_files).to receive(:create!)
      end

      it 'copies files from source to target version' do
        service.send(:copy_files_from_version, source_version, target_version)

        expect(target_version.builder_theme_files).to have_received(:create!).with(
          path: source_file.path,
          content: source_file.content,
          checksum: source_file.checksum,
          file_size: source_file.file_size
        )
      end
    end

    describe '#copy_files_from_theme_directory' do
      let(:theme_name) { 'test_theme' }
      let(:theme_path) { Rails.root.join('app', 'themes', theme_name) }

      before do
        allow(Dir).to receive(:exist?).with(theme_path).and_return(true)
        allow(service).to receive(:copy_files_recursive)
      end

      it 'copies files from theme directory' do
        service.send(:copy_files_from_theme_directory, theme_name, builder_theme)

        expect(service).to have_received(:copy_files_recursive).with(theme_path, builder_theme, '')
      end

      it 'returns early when theme directory does not exist' do
        allow(Dir).to receive(:exist?).with(theme_path).and_return(false)

        service.send(:copy_files_from_theme_directory, theme_name, builder_theme)

        expect(service).not_to have_received(:copy_files_recursive)
      end
    end

    describe '#copy_files_recursive' do
      let(:directory) { '/test/dir' }
      let(:relative_path) { 'subdir' }

      before do
        allow(Dir).to receive(:entries).with(directory).and_return(['.', '..', 'file1.liquid', 'subdir'])
        allow(File).to receive(:directory?).with('/test/dir/file1.liquid').and_return(false)
        allow(File).to receive(:directory?).with('/test/dir/subdir').and_return(true)
        allow(File).to receive(:read).with('/test/dir/file1.liquid').and_return('content')
        allow(builder_theme).to receive(:update_file)
        allow(service).to receive(:copy_files_recursive)
      end

      it 'copies files recursively' do
        service.send(:copy_files_recursive, directory, builder_theme, relative_path)

        expect(File).to have_received(:read).with('/test/dir/file1.liquid')
        expect(builder_theme).to have_received(:update_file).with('subdir/file1.liquid', 'content')
        expect(service).to have_received(:copy_files_recursive).with('/test/dir/subdir', builder_theme, 'subdir/subdir')
      end
    end

    describe '.copy_files_from_directory' do
      let(:directory) { '/test/dir' }
      let(:file_path) { '/test/dir/templates/index.liquid' }

      before do
        allow(Dir).to receive(:glob).with('/test/dir/**/*').and_return([file_path])
        allow(File).to receive(:directory?).with(file_path).and_return(false)
        allow(File).to receive(:read).with(file_path).and_return('content')
        allow(builder_theme).to receive(:update_file)
        allow(Pathname).to receive(:new).with(file_path).and_return(double(relative_path_from: double(to_s: 'templates/index.liquid')))
        allow(Pathname).to receive(:new).with(directory).and_return(double)
      end

      it 'copies files from directory' do
        BuilderThemeService.copy_files_from_directory(directory, builder_theme)

        expect(File).to have_received(:read).with(file_path)
        expect(builder_theme).to have_received(:update_file).with('templates/index.liquid', 'content')
      end
    end
  end
end

require 'rails_helper'

RSpec.describe ThemesManager, type: :service do
  let(:themes_path) { Rails.root.join('tmp', 'test_themes') }
  let(:service) { ThemesManager.new }
  let(:tenant) { create(:tenant) }

  before do
    # Set up test themes directory
    FileUtils.mkdir_p(themes_path)
    service.instance_variable_set(:@themes_path, themes_path)
    
    # Set current tenant
    ActsAsTenant.current_tenant = tenant
  end

  after do
    # Clean up test themes directory
    FileUtils.rm_rf(themes_path) if Dir.exist?(themes_path)
  end

  describe '#initialize' do
    it 'sets default themes path' do
      manager = ThemesManager.new
      expect(manager.themes_path).to eq(Rails.root.join('app', 'themes'))
    end

    it 'allows custom themes path' do
      custom_path = '/custom/path'
      manager = ThemesManager.new
      manager.themes_path = custom_path
      expect(manager.themes_path).to eq(custom_path)
    end
  end

  describe '#scan_themes' do
    context 'with valid theme directories' do
      before do
        # Create test theme directory
        theme_dir = File.join(themes_path, 'test_theme')
        FileUtils.mkdir_p(File.join(theme_dir, 'config'))
        
        # Create theme.json file
        theme_config = {
          name: 'Test Theme',
          description: 'A test theme',
          version: '1.0.0'
        }
        File.write(File.join(theme_dir, 'config', 'theme.json'), theme_config.to_json)
      end

      it 'scans and returns theme information' do
        themes = service.scan_themes
        
        expect(themes).to be_an(Array)
        expect(themes.length).to eq(1)
        
        theme = themes.first
        expect(theme[:name]).to eq('Test Theme')
        expect(theme[:slug]).to eq('test-theme')
        expect(theme[:description]).to eq('A test theme')
        expect(theme[:version]).to eq('1.0.0')
        expect(theme[:config]).to be_a(Hash)
      end
    end

    context 'with theme directory without config file' do
      before do
        theme_dir = File.join(themes_path, 'simple_theme')
        FileUtils.mkdir_p(theme_dir)
      end

      it 'returns theme with default values' do
        themes = service.scan_themes
        
        expect(themes).to be_an(Array)
        expect(themes.length).to eq(1)
        
        theme = themes.first
        expect(theme[:name]).to eq('simple_theme')
        expect(theme[:slug]).to eq('simple-theme')
        expect(theme[:description]).to eq('Theme: simple_theme')
        expect(theme[:version]).to eq('1.0.0')
        expect(theme[:config]).to eq({})
      end
    end

    context 'with non-existent themes directory' do
      before do
        service.instance_variable_set(:@themes_path, '/nonexistent/path')
      end

      it 'returns empty array' do
        themes = service.scan_themes
        expect(themes).to eq([])
      end
    end
  end

  describe '#sync_theme' do
    let(:theme_slug) { 'test_theme' }

    before do
      # Create test theme directory
      theme_dir = File.join(themes_path, theme_slug)
      FileUtils.mkdir_p(File.join(theme_dir, 'config'))
      
      # Create theme.json file
      theme_config = {
        name: 'Test Theme',
        description: 'A test theme',
        version: '1.0.0'
      }
      File.write(File.join(theme_dir, 'config', 'theme.json'), theme_config.to_json)
    end

    it 'syncs theme from filesystem to database' do
      theme = service.sync_theme(theme_slug)
      
      expect(theme).to be_a(Theme)
      expect(theme.name).to eq('Test Theme')
      expect(theme.slug).to eq(theme_slug)
      expect(theme.description).to eq('A test theme')
      expect(theme.version).to eq('1.0.0')
      expect(theme.tenant).to eq(tenant)
    end

    it 'returns false for non-existent theme' do
      result = service.sync_theme('nonexistent_theme')
      expect(result).to be false
    end

    it 'syncs theme files' do
      # Create some theme files
      theme_dir = File.join(themes_path, theme_slug)
      File.write(File.join(theme_dir, 'layout', 'theme.liquid'), '<html>{{ content }}</html>')
      File.write(File.join(theme_dir, 'templates', 'index.liquid'), '<h1>Homepage</h1>')
      
      theme = service.sync_theme(theme_slug)
      
      # Should create theme files
      expect(theme.theme_files.count).to be > 0
    end
  end

  describe '#sync_themes' do
    before do
      # Create multiple test themes
      ['theme1', 'theme2'].each do |theme_name|
        theme_dir = File.join(themes_path, theme_name)
        FileUtils.mkdir_p(File.join(theme_dir, 'config'))
        
        theme_config = {
          name: theme_name.titleize,
          description: "Theme #{theme_name}",
          version: '1.0.0'
        }
        File.write(File.join(theme_dir, 'config', 'theme.json'), theme_config.to_json)
      end
    end

    it 'syncs all themes from filesystem' do
      synced_count = service.sync_themes
      
      expect(synced_count).to be >= 0
      expect(Theme.count).to eq(2)
      
      themes = Theme.all
      expect(themes.map(&:name)).to include('Theme1', 'Theme2')
    end
  end

  describe '#active_theme' do
    it 'returns the active theme' do
      active_theme = create(:theme, active: true, tenant: tenant)
      create(:theme, active: false, tenant: tenant)
      
      result = service.active_theme
      expect(result).to eq(active_theme)
    end

    it 'returns nil when no active theme' do
      create(:theme, active: false, tenant: tenant)
      
      result = service.active_theme
      expect(result).to be_nil
    end
  end

  describe '#active_theme_version' do
    let(:active_theme) { create(:theme, active: true, tenant: tenant) }

    it 'returns active theme version' do
      theme_version = create(:theme_version, theme_name: active_theme.name, is_live: true)
      
      result = service.active_theme_version
      expect(result).to eq(theme_version)
    end

    it 'returns nil when no active theme' do
      create(:theme, active: false, tenant: tenant)
      
      result = service.active_theme_version
      expect(result).to be_nil
    end
  end

  describe '#get_file' do
    let(:theme) { create(:theme, name: 'test_theme', tenant: tenant) }
    let(:theme_version) { create(:theme_version, theme_name: theme.name, is_live: true) }

    before do
      # Create theme file
      theme_file = create(:theme_file, 
        theme_name: theme.name,
        file_path: 'layout/theme.liquid',
        theme_version: theme_version
      )
      create(:theme_file_version,
        theme_file: theme_file,
        content: '<html>{{ content }}</html>'
      )
    end

    it 'returns file content for active theme' do
      theme.update!(active: true)
      
      content = service.get_file('layout/theme.liquid')
      expect(content).to eq('<html>{{ content }}</html>')
    end

    it 'returns file content for specific theme' do
      content = service.get_file('layout/theme.liquid', theme.name)
      expect(content).to eq('<html>{{ content }}</html>')
    end

    it 'returns nil for non-existent file' do
      content = service.get_file('nonexistent/file.liquid')
      expect(content).to be_nil
    end
  end

  describe '#get_parsed_file' do
    let(:theme) { create(:theme, name: 'test_theme', tenant: tenant) }
    let(:theme_version) { create(:theme_version, theme_name: theme.name, is_live: true) }

    before do
      # Create JSON theme file
      theme_file = create(:theme_file,
        theme_name: theme.name,
        file_path: 'config/settings.json',
        theme_version: theme_version
      )
      create(:theme_file_version,
        theme_file: theme_file,
        content: '{"setting1": "value1", "setting2": "value2"}'
      )
    end

    it 'parses JSON files' do
      theme.update!(active: true)
      
      result = service.get_parsed_file('config/settings.json')
      expect(result).to eq({ 'setting1' => 'value1', 'setting2' => 'value2' })
    end

    it 'returns raw content for non-JSON files' do
      theme.update!(active: true)
      
      result = service.get_parsed_file('layout/theme.liquid')
      expect(result).to be_a(String)
    end

    it 'returns nil for invalid JSON' do
      theme_file = create(:theme_file,
        theme_name: theme.name,
        file_path: 'config/invalid.json',
        theme_version: theme_version
      )
      create(:theme_file_version,
        theme_file: theme_file,
        content: 'invalid json content'
      )
      
      theme.update!(active: true)
      
      result = service.get_parsed_file('config/invalid.json')
      expect(result).to be_nil
    end
  end

  describe '#create_file_version' do
    let(:theme) { create(:theme, active: true, tenant: tenant) }
    let(:theme_version) { create(:theme_version, theme_name: theme.name, is_live: true) }
    let(:theme_file) { create(:theme_file, theme_name: theme.name, theme_version: theme_version) }
    let(:user) { create(:user) }

    it 'creates new file version' do
      content = 'Updated content'
      
      version = service.create_file_version(theme_file, content, user)
      
      expect(version).to be_a(ThemeFileVersion)
      expect(version.content).to eq(content)
      expect(version.user).to eq(user)
      expect(version.change_summary).to eq('Edited via Monaco Editor')
    end

    it 'updates theme file checksum' do
      content = 'Updated content'
      old_checksum = theme_file.current_checksum
      
      service.create_file_version(theme_file, content, user)
      
      theme_file.reload
      expect(theme_file.current_checksum).not_to eq(old_checksum)
    end
  end

  describe '#theme_files' do
    let(:theme) { create(:theme, name: 'test_theme', tenant: tenant) }
    let(:theme_version) { create(:theme_version, theme_name: theme.name, is_live: true) }

    before do
      create(:theme_file, theme_name: theme.name, theme_version: theme_version)
      create(:theme_file, theme_name: theme.name, theme_version: theme_version)
    end

    it 'returns all files for theme' do
      files = service.theme_files(theme.name)
      
      expect(files).to be_an(Array)
      expect(files.length).to eq(2)
    end

    it 'returns empty array for non-existent theme' do
      files = service.theme_files('nonexistent_theme')
      expect(files).to eq([])
    end
  end

  describe '#file_tree' do
    let(:theme) { create(:theme, name: 'test_theme', tenant: tenant) }
    let(:theme_version) { create(:theme_version, theme_name: theme.name, is_live: true) }

    before do
      # Create theme files with different paths
      create(:theme_file, 
        theme_name: theme.name,
        file_path: File.join(themes_path, theme.name, 'layout/theme.liquid'),
        theme_version: theme_version
      )
      create(:theme_file,
        theme_name: theme.name,
        file_path: File.join(themes_path, theme.name, 'templates/index.liquid'),
        theme_version: theme_version
      )
    end

    it 'returns file tree structure' do
      tree = service.file_tree(theme.name)
      
      expect(tree).to be_an(Array)
      expect(tree).to include(hash_including(name: 'layout', type: 'directory'))
      expect(tree).to include(hash_including(name: 'templates', type: 'directory'))
    end
  end

  describe '#check_for_updates' do
    let(:theme) { create(:theme, name: 'test_theme', version: '1.0.0', tenant: tenant) }

    before do
      # Create theme directory with updated version
      theme_dir = File.join(themes_path, theme.name)
      FileUtils.mkdir_p(File.join(theme_dir, 'config'))
      
      theme_config = {
        name: theme.name,
        version: '2.0.0'
      }
      File.write(File.join(theme_dir, 'config', 'theme.json'), theme_config.to_json)
    end

    it 'detects theme updates' do
      has_updates = service.check_for_updates(theme)
      expect(has_updates).to be true
    end

    it 'returns false when no updates' do
      theme.update!(version: '2.0.0')
      
      has_updates = service.check_for_updates(theme)
      expect(has_updates).to be false
    end

    it 'returns false for non-existent theme' do
      has_updates = service.check_for_updates(nil)
      expect(has_updates).to be false
    end
  end

  describe 'file operations' do
    let(:theme) { create(:theme, active: true, tenant: tenant) }
    let(:theme_version) { create(:theme_version, theme_name: theme.name, is_live: true) }

    before do
      # Create theme directory
      theme_dir = File.join(themes_path, theme.name)
      FileUtils.mkdir_p(theme_dir)
    end

    describe '#create_file' do
      it 'creates new file' do
        file_path = 'templates/test.liquid'
        content = '<h1>Test</h1>'
        
        result = service.create_file(file_path, content)
        
        expect(result).to be true
        
        # Check file was created on filesystem
        full_path = File.join(themes_path, theme.name, file_path)
        expect(File.exist?(full_path)).to be true
        expect(File.read(full_path)).to eq(content)
        
        # Check theme file was created in database
        theme_file = ThemeFile.find_by(theme_name: theme.name, file_path: file_path)
        expect(theme_file).to be_present
      end

      it 'prevents path traversal attacks' do
        result = service.create_file('../../../etc/passwd', 'malicious content')
        expect(result).to be false
      end
    end

    describe '#delete_file' do
      it 'deletes existing file' do
        file_path = 'templates/test.liquid'
        full_path = File.join(themes_path, theme.name, file_path)
        File.write(full_path, 'test content')
        
        result = service.delete_file(file_path)
        
        expect(result).to be true
        expect(File.exist?(full_path)).to be false
      end

      it 'returns false for non-existent file' do
        result = service.delete_file('nonexistent/file.liquid')
        expect(result).to be false
      end
    end

    describe '#rename_file' do
      it 'renames existing file' do
        old_path = 'templates/old.liquid'
        new_path = 'templates/new.liquid'
        
        old_full_path = File.join(themes_path, theme.name, old_path)
        File.write(old_full_path, 'test content')
        
        result = service.rename_file(old_path, new_path)
        
        expect(result).to be true
        expect(File.exist?(old_full_path)).to be false
        
        new_full_path = File.join(themes_path, theme.name, new_path)
        expect(File.exist?(new_full_path)).to be true
        expect(File.read(new_full_path)).to eq('test content')
      end
    end
  end

  describe '#search' do
    let(:theme) { create(:theme, active: true, tenant: tenant) }

    before do
      # Create theme directory with test files
      theme_dir = File.join(themes_path, theme.name)
      FileUtils.mkdir_p(theme_dir)
      
      File.write(File.join(theme_dir, 'layout', 'theme.liquid'), '<html>{{ content }}</html>')
      File.write(File.join(theme_dir, 'templates', 'index.liquid'), '<h1>Welcome to {{ site.name }}</h1>')
    end

    it 'searches for text in theme files' do
      results = service.search('content')
      
      expect(results).to be_an(Array)
      expect(results.length).to be > 0
      
      result = results.first
      expect(result).to include(:file, :line, :content, :match)
    end

    it 'returns empty array for blank query' do
      results = service.search('')
      expect(results).to eq([])
    end
  end

  describe 'private methods' do
    describe '#determine_file_type' do
      it 'determines file type based on path' do
        expect(service.send(:determine_file_type, 'templates/index.liquid')).to eq('template')
        expect(service.send(:determine_file_type, 'sections/header.liquid')).to eq('section')
        expect(service.send(:determine_file_type, 'layout/theme.liquid')).to eq('layout')
        expect(service.send(:determine_file_type, 'assets/style.css')).to eq('asset')
        expect(service.send(:determine_file_type, 'config/settings.json')).to eq('config')
        expect(service.send(:determine_file_type, 'other/file.txt')).to eq('other')
      end
    end

    describe '#editable_file?' do
      it 'determines if file is editable' do
        expect(service.send(:editable_file?, 'template.liquid')).to be true
        expect(service.send(:editable_file?, 'style.css')).to be true
        expect(service.send(:editable_file?, 'script.js')).to be true
        expect(service.send(:editable_file?, 'config.json')).to be true
        expect(service.send(:editable_file?, 'image.png')).to be false
        expect(service.send(:editable_file?, 'document.pdf')).to be false
      end
    end

    describe '#valid_file_path?' do
      it 'validates file paths' do
        expect(service.send(:valid_file_path?, 'templates/index.liquid')).to be true
        expect(service.send(:valid_file_path?, 'templates/index.liquid')).to be true
        expect(service.send(:valid_file_path?, '../etc/passwd')).to be false
        expect(service.send(:valid_file_path?, '/absolute/path')).to be false
        expect(service.send(:valid_file_path?, 'normal/path/file.liquid')).to be true
      end
    end
  end
end

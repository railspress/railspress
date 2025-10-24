class UpdateAiProvidersRemoveTemperatureAddSlugAndUuid < ActiveRecord::Migration[7.1]
  def change
    # Remove temperature column (agents have their own now)
    remove_column :ai_providers, :temperature, :decimal
    
    # Add slug column
    add_column :ai_providers, :slug, :string
    add_index :ai_providers, :slug, unique: true
    
    # Add uuid column
    add_column :ai_providers, :uuid, :string
    add_index :ai_providers, :uuid, unique: true
    
    # Generate slugs and UUIDs for existing records
    reversible do |dir|
      dir.up do
        AiProvider.find_each do |provider|
          # Generate slug from provider_type, append ID to ensure uniqueness
          slug = provider.provider_type || 'unknown'
          slug = "#{slug}_#{provider.id}" if provider.slug.nil? || AiProvider.where(slug: slug).where.not(id: provider.id).exists?
          
          provider.update_columns(
            slug: slug,
            uuid: SecureRandom.uuid
          )
        end
      end
    end
  end
end

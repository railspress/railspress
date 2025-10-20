class CreateImageOptimizationLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :image_optimization_logs do |t|
      t.references :medium, null: false, foreign_key: true
      t.references :upload, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :tenant, null: false, foreign_key: true
      
      # File information
      t.string :filename
      t.string :content_type
      t.integer :original_size
      t.integer :optimized_size
      t.integer :width
      t.integer :height
      
      # Optimization settings
      t.string :compression_level
      t.integer :quality
      t.boolean :strip_metadata
      t.boolean :enable_webp
      t.boolean :enable_avif
      
      # Performance metrics
      t.decimal :processing_time, precision: 10, scale: 3
      t.decimal :size_reduction_percentage, precision: 5, scale: 2
      t.integer :bytes_saved
      
      # Variants information
      t.text :variants_generated
      t.text :responsive_variants_generated
      
      # Optimization details
      t.string :optimization_type # 'upload', 'bulk', 'manual', 'regenerate'
      t.string :status # 'success', 'failed', 'skipped', 'partial'
      t.text :error_message
      t.text :warnings
      
      # Additional metadata
      t.string :storage_provider
      t.boolean :cdn_enabled
      t.string :user_agent
      t.string :ip_address
      
      t.timestamps
    end
    
    # Add indexes for performance
    add_index :image_optimization_logs, [:medium_id, :created_at]
    add_index :image_optimization_logs, [:upload_id, :created_at]
    add_index :image_optimization_logs, [:user_id, :created_at]
    add_index :image_optimization_logs, [:tenant_id, :created_at]
    add_index :image_optimization_logs, [:compression_level, :created_at]
    add_index :image_optimization_logs, [:status, :created_at]
    add_index :image_optimization_logs, [:optimization_type, :created_at]
    add_index :image_optimization_logs, :created_at
  end
end

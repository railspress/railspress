module Types
  class GdprType < Types::BaseObject
    description "GDPR compliance information"
    
    field :user_id, ID, null: false, description: "User ID"
    field :email, String, null: false, description: "User email"
    
    field :compliance_status, Types::GdprComplianceStatusType, null: false, description: "GDPR compliance status"
    field :data_retention, Types::GdprDataRetentionType, null: false, description: "Data retention information"
    field :pending_requests, Types::GdprPendingRequestsType, null: false, description: "Pending GDPR requests"
    field :data_categories, Types::GdprDataCategoriesType, null: false, description: "Data categories held"
    field :legal_basis, Types::GdprLegalBasisType, null: false, description: "Legal basis for processing"
    
    field :export_requests, [Types::GdprExportRequestType], null: false, description: "Data export requests"
    field :erasure_requests, [Types::GdprErasureRequestType], null: false, description: "Data erasure requests"
    field :consent_records, [Types::GdprConsentRecordType], null: false, description: "User consent records"
    
    def export_requests
      PersonalDataExportRequest.where(user_id: object[:user_id])
    end
    
    def erasure_requests
      PersonalDataErasureRequest.where(user_id: object[:user_id])
    end
    
    def consent_records
      UserConsent.where(user_id: object[:user_id])
    end
  end
  
  class GdprComplianceStatusType < Types::BaseObject
    description "GDPR compliance status"
    
    field :data_processing_consent, String, null: false, description: "Data processing consent status"
    field :marketing_consent, String, null: false, description: "Marketing consent status"
    field :analytics_consent, String, null: false, description: "Analytics consent status"
    field :cookie_consent, String, null: false, description: "Cookie consent status"
  end
  
  class GdprDataRetentionType < Types::BaseObject
    description "Data retention information"
    
    field :account_created, GraphQL::Types::ISO8601DateTime, null: false, description: "Account creation date"
    field :last_activity, GraphQL::Types::ISO8601DateTime, null: true, description: "Last activity date"
    field :data_age_days, Integer, null: false, description: "Data age in days"
  end
  
  class GdprPendingRequestsType < Types::BaseObject
    description "Pending GDPR requests"
    
    field :export_requests, Integer, null: false, description: "Number of pending export requests"
    field :erasure_requests, Integer, null: false, description: "Number of pending erasure requests"
  end
  
  class GdprDataCategoriesType < Types::BaseObject
    description "Data categories held"
    
    field :profile_data, Boolean, null: false, description: "Profile data held"
    field :content_data, Boolean, null: false, description: "Content data held"
    field :communication_data, Boolean, null: false, description: "Communication data held"
    field :analytics_data, Boolean, null: false, description: "Analytics data held"
    field :media_data, Boolean, null: false, description: "Media data held"
    field :subscription_data, Boolean, null: false, description: "Subscription data held"
  end
  
  class GdprLegalBasisType < Types::BaseObject
    description "Legal basis for processing"
    
    field :consent, Boolean, null: false, description: "Processing based on consent"
    field :withhold_consent, Boolean, null: false, description: "Consent has been withdrawn"
    field :legitimate_interest, Boolean, null: false, description: "Processing based on legitimate interest"
  end
  
  class GdprExportRequestType < Types::BaseObject
    description "GDPR data export request"
    
    field :id, ID, null: false, description: "Request ID"
    field :email, String, null: false, description: "User email"
    field :status, String, null: false, description: "Request status"
    field :requested_at, GraphQL::Types::ISO8601DateTime, null: false, description: "Request date"
    field :completed_at, GraphQL::Types::ISO8601DateTime, null: true, description: "Completion date"
    field :download_url, String, null: true, description: "Download URL (if completed)"
    field :token, String, null: false, description: "Access token"
  end
  
  class GdprErasureRequestType < Types::BaseObject
    description "GDPR data erasure request"
    
    field :id, ID, null: false, description: "Request ID"
    field :email, String, null: false, description: "User email"
    field :status, String, null: false, description: "Request status"
    field :reason, String, null: true, description: "Erasure reason"
    field :requested_at, GraphQL::Types::ISO8601DateTime, null: false, description: "Request date"
    field :confirmed_at, GraphQL::Types::ISO8601DateTime, null: true, description: "Confirmation date"
    field :completed_at, GraphQL::Types::ISO8601DateTime, null: true, description: "Completion date"
    field :confirmation_url, String, null: true, description: "Confirmation URL (if pending)"
    field :metadata, GraphQL::Types::JSON, null: true, description: "Request metadata"
  end
  
  class GdprConsentRecordType < Types::BaseObject
    description "GDPR consent record"
    
    field :id, ID, null: false, description: "Record ID"
    field :consent_type, String, null: false, description: "Type of consent"
    field :granted, Boolean, null: false, description: "Whether consent is granted"
    field :consent_text, String, null: false, description: "Consent text"
    field :granted_at, GraphQL::Types::ISO8601DateTime, null: true, description: "Grant date"
    field :withdrawn_at, GraphQL::Types::ISO8601DateTime, null: true, description: "Withdrawal date"
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false, description: "Creation date"
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false, description: "Last update date"
  end
  
  class GdprDataPortabilityType < Types::BaseObject
    description "GDPR data portability information"
    
    field :user_profile, GraphQL::Types::JSON, null: false, description: "User profile data"
    field :posts, [GraphQL::Types::JSON], null: false, description: "User posts"
    field :pages, [GraphQL::Types::JSON], null: false, description: "User pages"
    field :comments, [GraphQL::Types::JSON], null: false, description: "User comments"
    field :media, [GraphQL::Types::JSON], null: false, description: "User media"
    field :subscribers, [GraphQL::Types::JSON], null: false, description: "User subscriptions"
    field :api_tokens, [GraphQL::Types::JSON], null: false, description: "User API tokens"
    field :meta_fields, [GraphQL::Types::JSON], null: false, description: "User meta fields"
    field :analytics_data, GraphQL::Types::JSON, null: false, description: "User analytics data"
    field :consent_records, [GraphQL::Types::JSON], null: false, description: "User consent records"
    field :gdpr_requests, GraphQL::Types::JSON, null: false, description: "GDPR requests history"
    field :metadata, GraphQL::Types::JSON, null: false, description: "Export metadata"
  end
  
  class GdprAuditLogEntryType < Types::BaseObject
    description "GDPR audit log entry"
    
    field :id, ID, null: false, description: "Entry ID"
    field :action, String, null: false, description: "Action performed"
    field :user_email, String, null: false, description: "User email"
    field :timestamp, GraphQL::Types::ISO8601DateTime, null: false, description: "Action timestamp"
    field :details, GraphQL::Types::JSON, null: true, description: "Action details"
  end
end

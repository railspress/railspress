module Mutations
  module GdprMutations
    # Request personal data export
    class RequestDataExport < Mutations::BaseMutation
      description "Request export of personal data (GDPR Article 20 - Right to Data Portability)"
      
      argument :user_id, ID, required: true, description: "User ID to export data for"
      
      field :success, Boolean, null: false, description: "Whether the request was successful"
      field :message, String, null: false, description: "Response message"
      field :export_request, Types::GdprExportRequestType, null: true, description: "Created export request"
      field :errors, [String], null: true, description: "List of errors"
      
      def resolve(user_id:)
        user = User.find(user_id)
        
        # Check permissions
        unless context[:current_user]&.administrator? || context[:current_user] == user
          return {
            success: false,
            message: 'Access denied',
            export_request: nil,
            errors: ['Insufficient permissions']
          }
        end
        
        begin
          export_request = GdprService.create_export_request(user, context[:current_user])
          
          {
            success: true,
            message: 'Personal data export request created successfully',
            export_request: export_request,
            errors: nil
          }
        rescue => e
          {
            success: false,
            message: 'Failed to create export request',
            export_request: nil,
            errors: [e.message]
          }
        end
      end
    end
    
    # Request personal data erasure
    class RequestDataErasure < Mutations::BaseMutation
      description "Request erasure of personal data (GDPR Article 17 - Right to Erasure)"
      
      argument :user_id, ID, required: true, description: "User ID to erase data for"
      argument :reason, String, required: false, description: "Reason for data erasure"
      
      field :success, Boolean, null: false, description: "Whether the request was successful"
      field :message, String, null: false, description: "Response message"
      field :erasure_request, Types::GdprErasureRequestType, null: true, description: "Created erasure request"
      field :errors, [String], null: true, description: "List of errors"
      
      def resolve(user_id:, reason: nil)
        user = User.find(user_id)
        
        # Check permissions
        unless context[:current_user]&.administrator? || context[:current_user] == user
          return {
            success: false,
            message: 'Access denied',
            erasure_request: nil,
            errors: ['Insufficient permissions']
          }
        end
        
        # Prevent admins from being erased
        if user.administrator?
          return {
            success: false,
            message: 'Cannot erase data for administrator accounts',
            erasure_request: nil,
            errors: ['Administrator accounts cannot be erased']
          }
        end
        
        begin
          erasure_request = GdprService.create_erasure_request(user, context[:current_user], reason)
          
          {
            success: true,
            message: 'Data erasure request created successfully',
            erasure_request: erasure_request,
            errors: nil
          }
        rescue => e
          {
            success: false,
            message: 'Failed to create erasure request',
            erasure_request: nil,
            errors: [e.message]
          }
        end
      end
    end
    
    # Confirm data erasure request
    class ConfirmDataErasure < Mutations::BaseMutation
      description "Confirm a data erasure request"
      
      argument :token, String, required: true, description: "Erasure request token"
      
      field :success, Boolean, null: false, description: "Whether the confirmation was successful"
      field :message, String, null: false, description: "Response message"
      field :erasure_request, Types::GdprErasureRequestType, null: true, description: "Confirmed erasure request"
      field :errors, [String], null: true, description: "List of errors"
      
      def resolve(token:)
        erasure_request = PersonalDataErasureRequest.find_by(token: token)
        
        unless erasure_request
          return {
            success: false,
            message: 'Erasure request not found',
            erasure_request: nil,
            errors: ['Invalid token']
          }
        end
        
        if erasure_request.status != 'pending_confirmation'
          return {
            success: false,
            message: 'This request has already been processed',
            erasure_request: erasure_request,
            errors: ['Request already processed']
          }
        end
        
        begin
          GdprService.confirm_erasure_request(erasure_request, context[:current_user])
          
          {
            success: true,
            message: 'Data erasure confirmed and queued for processing',
            erasure_request: erasure_request,
            errors: nil
          }
        rescue => e
          {
            success: false,
            message: 'Failed to confirm erasure request',
            erasure_request: nil,
            errors: [e.message]
          }
        end
      end
    end
    
    # Record user consent
    class RecordConsent < Mutations::BaseMutation
      description "Record user consent (GDPR Article 7)"
      
      argument :user_id, ID, required: true, description: "User ID"
      argument :consent_type, String, required: true, description: "Type of consent"
      argument :consent_data, GraphQL::Types::JSON, required: true, description: "Consent data"
      
      field :success, Boolean, null: false, description: "Whether the consent was recorded successfully"
      field :message, String, null: false, description: "Response message"
      field :consent_record, Types::GdprConsentRecordType, null: true, description: "Created consent record"
      field :errors, [String], null: true, description: "List of errors"
      
      def resolve(user_id:, consent_type:, consent_data:)
        user = User.find(user_id)
        
        # Check permissions
        unless context[:current_user]&.administrator? || context[:current_user] == user
          return {
            success: false,
            message: 'Access denied',
            consent_record: nil,
            errors: ['Insufficient permissions']
          }
        end
        
        begin
          consent_record = GdprService.record_user_consent(user, consent_type, consent_data)
          
          {
            success: true,
            message: 'Consent recorded successfully',
            consent_record: consent_record,
            errors: nil
          }
        rescue => e
          {
            success: false,
            message: 'Failed to record consent',
            consent_record: nil,
            errors: [e.message]
          }
        end
      end
    end
    
    # Withdraw user consent
    class WithdrawConsent < Mutations::BaseMutation
      description "Withdraw user consent"
      
      argument :user_id, ID, required: true, description: "User ID"
      argument :consent_type, String, required: true, description: "Type of consent to withdraw"
      
      field :success, Boolean, null: false, description: "Whether the consent was withdrawn successfully"
      field :message, String, null: false, description: "Response message"
      field :consent_record, Types::GdprConsentRecordType, null: true, description: "Updated consent record"
      field :errors, [String], null: true, description: "List of errors"
      
      def resolve(user_id:, consent_type:)
        user = User.find(user_id)
        
        # Check permissions
        unless context[:current_user]&.administrator? || context[:current_user] == user
          return {
            success: false,
            message: 'Access denied',
            consent_record: nil,
            errors: ['Insufficient permissions']
          }
        end
        
        begin
          consent_record = GdprService.withdraw_user_consent(user, consent_type)
          
          {
            success: true,
            message: 'Consent withdrawn successfully',
            consent_record: consent_record,
            errors: nil
          }
        rescue => e
          {
            success: false,
            message: 'Failed to withdraw consent',
            consent_record: nil,
            errors: [e.message]
          }
        end
      end
    end
  end
end

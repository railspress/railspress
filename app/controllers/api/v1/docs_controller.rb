module Api
  module V1
    class DocsController < ApplicationController
      skip_before_action :verify_authenticity_token
      
      def index
        @api_endpoints = build_endpoint_tree
        render layout: 'api_docs'
      end
      
      private
      
      def build_endpoint_tree
        {
          authentication: {
            name: 'Authentication',
            endpoints: [
              { method: 'POST', path: '/api/v1/auth/login', description: 'Login and get API token' },
              { method: 'POST', path: '/api/v1/auth/register', description: 'Register new user' },
              { method: 'POST', path: '/api/v1/auth/validate', description: 'Validate API token' }
            ]
          },
          posts: {
            name: 'Posts',
            endpoints: [
              { method: 'GET', path: '/api/v1/posts', description: 'List all posts' },
              { method: 'GET', path: '/api/v1/posts/:id', description: 'Get single post' },
              { method: 'POST', path: '/api/v1/posts', description: 'Create new post', auth: true },
              { method: 'PATCH', path: '/api/v1/posts/:id', description: 'Update post', auth: true },
              { method: 'DELETE', path: '/api/v1/posts/:id', description: 'Delete post', auth: true }
            ]
          },
          pages: {
            name: 'Pages',
            endpoints: [
              { method: 'GET', path: '/api/v1/pages', description: 'List all pages' },
              { method: 'GET', path: '/api/v1/pages/:id', description: 'Get single page' },
              { method: 'POST', path: '/api/v1/pages', description: 'Create new page', auth: true },
              { method: 'PATCH', path: '/api/v1/pages/:id', description: 'Update page', auth: true },
              { method: 'DELETE', path: '/api/v1/pages/:id', description: 'Delete page', auth: true }
            ]
          },
          categories: {
            name: 'Categories',
            endpoints: [
              { method: 'GET', path: '/api/v1/categories', description: 'List all categories' },
              { method: 'GET', path: '/api/v1/categories/:id', description: 'Get single category' },
              { method: 'POST', path: '/api/v1/categories', description: 'Create category', auth: true },
              { method: 'PATCH', path: '/api/v1/categories/:id', description: 'Update category', auth: true },
              { method: 'DELETE', path: '/api/v1/categories/:id', description: 'Delete category', auth: true }
            ]
          },
          tags: {
            name: 'Tags',
            endpoints: [
              { method: 'GET', path: '/api/v1/tags', description: 'List all tags' },
              { method: 'GET', path: '/api/v1/tags/:id', description: 'Get single tag' },
              { method: 'POST', path: '/api/v1/tags', description: 'Create tag', auth: true },
              { method: 'PATCH', path: '/api/v1/tags/:id', description: 'Update tag', auth: true },
              { method: 'DELETE', path: '/api/v1/tags/:id', description: 'Delete tag', auth: true }
            ]
          },
          comments: {
            name: 'Comments',
            endpoints: [
              { method: 'GET', path: '/api/v1/comments', description: 'List all comments' },
              { method: 'GET', path: '/api/v1/comments/:id', description: 'Get single comment' },
              { method: 'POST', path: '/api/v1/comments', description: 'Create comment' },
              { method: 'PATCH', path: '/api/v1/comments/:id/approve', description: 'Approve comment', auth: true },
              { method: 'PATCH', path: '/api/v1/comments/:id/spam', description: 'Mark as spam', auth: true },
              { method: 'DELETE', path: '/api/v1/comments/:id', description: 'Delete comment', auth: true }
            ]
          },
          media: {
            name: 'Media',
            endpoints: [
              { method: 'GET', path: '/api/v1/media', description: 'List all media' },
              { method: 'GET', path: '/api/v1/media/:id', description: 'Get single media' },
              { method: 'POST', path: '/api/v1/media', description: 'Upload media', auth: true },
              { method: 'PATCH', path: '/api/v1/media/:id', description: 'Update media', auth: true },
              { method: 'DELETE', path: '/api/v1/media/:id', description: 'Delete media', auth: true }
            ]
          },
          users: {
            name: 'Users',
            endpoints: [
              { method: 'GET', path: '/api/v1/users', description: 'List all users', auth: true, admin: true },
              { method: 'GET', path: '/api/v1/users/me', description: 'Get current user', auth: true },
              { method: 'PATCH', path: '/api/v1/users/update_profile', description: 'Update profile', auth: true },
              { method: 'POST', path: '/api/v1/users/regenerate_token', description: 'Regenerate API token', auth: true }
            ]
          },
          menus: {
            name: 'Menus',
            endpoints: [
              { method: 'GET', path: '/api/v1/menus', description: 'List all menus' },
              { method: 'GET', path: '/api/v1/menus/:id', description: 'Get menu with items' }
            ]
          },
          settings: {
            name: 'Settings',
            endpoints: [
              { method: 'GET', path: '/api/v1/settings', description: 'List all settings', auth: true },
              { method: 'GET', path: '/api/v1/settings/get/:key', description: 'Get setting value', auth: true },
              { method: 'POST', path: '/api/v1/settings', description: 'Create setting', auth: true, admin: true }
            ]
          },
          system: {
            name: 'System',
            endpoints: [
              { method: 'GET', path: '/api/v1/system/info', description: 'Get API information' },
              { method: 'GET', path: '/api/v1/system/stats', description: 'Get system statistics', auth: true, admin: true }
            ]
          }
        }
      end
    end
  end
end









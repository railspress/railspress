// Shared column configurations for admin tables

export const commonColumns = {
  // Checkbox column for bulk selection
  checkbox: {
    title: "",
    formatter: "rowSelection",
    titleFormatter: "rowSelection",
    width: 40,
    headerSort: false,
    cellClick: function(e, cell) {
      cell.getRow().toggleSelect();
    }
  },

  // Status column with badges
  status: {
    title: "Status",
    field: "status",
    width: 100,
    formatter: function(cell, formatterParams) {
      const value = cell.getValue();
      const statusMap = {
        'published': { class: 'bg-green-100 text-green-800', label: 'Published' },
        'draft': { class: 'bg-yellow-100 text-yellow-800', label: 'Draft' },
        'pending': { class: 'bg-blue-100 text-blue-800', label: 'Pending' },
        'trash': { class: 'bg-red-100 text-red-800', label: 'Trash' },
        'approved': { class: 'bg-green-100 text-green-800', label: 'Approved' },
        'spam': { class: 'bg-red-100 text-red-800', label: 'Spam' },
        'pending_review': { class: 'bg-yellow-100 text-yellow-800', label: 'Pending Review' }
      };
      
      const status = statusMap[value] || { class: 'bg-gray-100 text-gray-800', label: value };
      return `<span class="px-2 py-1 text-xs font-medium rounded-full ${status.class}">${status.label}</span>`;
    }
  },

  // Date column with formatting
  date: {
    title: "Date",
    field: "created_at",
    width: 150,
    formatter: function(cell, formatterParams) {
      const date = new Date(cell.getValue());
      return date.toLocaleDateString() + ' ' + date.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'});
    }
  },

  // Actions column with buttons
  actions: {
    title: "Actions",
    field: "actions",
    width: 120,
    headerSort: false,
    formatter: function(cell, formatterParams) {
      const data = cell.getRow().getData();
      let actions = '';
      
      if (data.edit_url) {
        actions += `<a href="${data.edit_url}" class="text-indigo-600 hover:text-indigo-900 mr-2" title="Edit">✏️</a>`;
      }
      
      if (data.show_url) {
        actions += `<a href="${data.show_url}" class="text-blue-600 hover:text-blue-900 mr-2" title="View">👁️</a>`;
      }
      
      if (data.delete_url) {
        actions += `<a href="${data.delete_url}" class="text-red-600 hover:text-red-900" title="Delete" data-confirm="Are you sure?">🗑️</a>`;
      }
      
      return actions;
    }
  }
};

// Posts specific columns
export const postsColumns = [
  commonColumns.checkbox,
  {
    title: "Title",
    field: "title",
    width: 300,
    formatter: function(cell, formatterParams) {
      const data = cell.getRow().getData();
      return `<a href="${data.edit_url}" class="text-indigo-600 hover:text-indigo-900 font-medium">${data.title}</a>`;
    }
  },
  {
    title: "Author",
    field: "author_name",
    width: 150
  },
  commonColumns.status,
  {
    title: "Categories",
    field: "categories",
    width: 150,
    formatter: function(cell, formatterParams) {
      const categories = cell.getValue();
      if (!categories || categories.length === 0) return '<span class="text-gray-400">Uncategorized</span>';
      return categories.map(cat => `<span class="px-2 py-1 text-xs bg-gray-100 text-gray-800 rounded mr-1">${cat}</span>`).join('');
    }
  },
  {
    title: "Tags",
    field: "tags",
    width: 150,
    formatter: function(cell, formatterParams) {
      const tags = cell.getValue();
      if (!tags || tags.length === 0) return '';
      return tags.map(tag => `<span class="px-2 py-1 text-xs bg-blue-100 text-blue-800 rounded mr-1">${tag}</span>`).join('');
    }
  },
  commonColumns.date,
  commonColumns.actions
];

// Pages specific columns
export const pagesColumns = [
  commonColumns.checkbox,
  {
    title: "Title",
    field: "title",
    width: 300,
    formatter: function(cell, formatterParams) {
      const data = cell.getRow().getData();
      return `<a href="${data.edit_url}" class="text-indigo-600 hover:text-indigo-900 font-medium">${data.title}</a>`;
    }
  },
  {
    title: "Author",
    field: "author_name",
    width: 150
  },
  commonColumns.status,
  {
    title: "Template",
    field: "template",
    width: 120,
    formatter: function(cell, formatterParams) {
      const template = cell.getValue();
      return template || '<span class="text-gray-400">Default</span>';
    }
  },
  commonColumns.date,
  commonColumns.actions
];

// Comments specific columns
export const commentsColumns = [
  commonColumns.checkbox,
  {
    title: "Author",
    field: "author_name",
    width: 150
  },
  {
    title: "Comment",
    field: "content",
    width: 300,
    formatter: function(cell, formatterParams) {
      const content = cell.getValue();
      return content.length > 100 ? content.substring(0, 100) + '...' : content;
    }
  },
  {
    title: "In Response To",
    field: "commentable_title",
    width: 150,
    formatter: function(cell, formatterParams) {
      const data = cell.getRow().getData();
      if (data.commentable_url) {
        return `<a href="${data.commentable_url}" class="text-indigo-600 hover:text-indigo-900">${data.commentable_title}</a>`;
      }
      return data.commentable_title;
    }
  },
  commonColumns.status,
  commonColumns.date,
  commonColumns.actions
];

// Media specific columns
export const mediaColumns = [
  commonColumns.checkbox,
  {
    title: "File",
    field: "filename",
    width: 200,
    formatter: function(cell, formatterParams) {
      const data = cell.getRow().getData();
      if (data.thumbnail_url) {
        return `<div class="flex items-center space-x-2">
          <img src="${data.thumbnail_url}" class="w-8 h-8 object-cover rounded" />
          <span class="font-medium">${data.filename}</span>
        </div>`;
      }
      return data.filename;
    }
  },
  {
    title: "Title",
    field: "title",
    width: 200
  },
  {
    title: "Type",
    field: "content_type",
    width: 100
  },
  {
    title: "Size",
    field: "file_size",
    width: 100,
    formatter: function(cell, formatterParams) {
      const bytes = cell.getValue();
      if (!bytes) return '';
      const sizes = ['Bytes', 'KB', 'MB', 'GB'];
      const i = Math.floor(Math.log(bytes) / Math.log(1024));
      return Math.round(bytes / Math.pow(1024, i) * 100) / 100 + ' ' + sizes[i];
    }
  },
  commonColumns.date,
  commonColumns.actions
];


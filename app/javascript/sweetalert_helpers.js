// SweetAlert2 Helper Functions for RailsPress
// Provides consistent toast and alert styling across the admin panel

window.Toast = Swal.mixin({
  toast: true,
  position: 'top-end',
  showConfirmButton: false,
  timer: 3000,
  timerProgressBar: true,
  didOpen: (toast) => {
    toast.addEventListener('mouseenter', Swal.stopTimer)
    toast.addEventListener('mouseleave', Swal.resumeTimer)
  }
})

// Success toast
window.showSuccessToast = (message) => {
  Toast.fire({
    icon: 'success',
    title: message
  })
}

// Error toast
window.showErrorToast = (message) => {
  Toast.fire({
    icon: 'error',
    title: message
  })
}

// Info toast
window.showInfoToast = (message) => {
  Toast.fire({
    icon: 'info',
    title: message
  })
}

// Warning toast
window.showWarningToast = (message) => {
  Toast.fire({
    icon: 'warning',
    title: message
  })
}

// Success alert (modal)
window.showSuccessAlert = (title, message) => {
  return Swal.fire({
    icon: 'success',
    title: title,
    text: message,
    confirmButtonText: 'OK'
  })
}

// Error alert (modal)
window.showErrorAlert = (title, message) => {
  return Swal.fire({
    icon: 'error',
    title: title,
    text: message,
    confirmButtonText: 'OK'
  })
}

// Confirmation dialog
window.showConfirmDialog = (title, message, confirmText = 'Yes', cancelText = 'No') => {
  return Swal.fire({
    title: title,
    text: message,
    icon: 'question',
    showCancelButton: true,
    confirmButtonText: confirmText,
    cancelButtonText: cancelText,
    reverseButtons: true
  })
}

// Delete confirmation
window.showDeleteConfirm = (itemName = 'this item') => {
  return Swal.fire({
    title: 'Are you sure?',
    text: `Do you want to delete ${itemName}? This action cannot be undone.`,
    icon: 'warning',
    showCancelButton: true,
    confirmButtonText: 'Yes, delete it',
    cancelButtonText: 'Cancel',
    confirmButtonColor: '#ef4444',
    reverseButtons: true
  })
}

// Loading alert
window.showLoading = (title = 'Processing...') => {
  Swal.fire({
    title: title,
    allowOutsideClick: false,
    allowEscapeKey: false,
    showConfirmButton: false,
    didOpen: () => {
      Swal.showLoading()
    }
  })
}

// Close loading
window.closeLoading = () => {
  Swal.close()
}

// Input dialog
window.showInputDialog = (title, inputPlaceholder, inputType = 'text') => {
  return Swal.fire({
    title: title,
    input: inputType,
    inputPlaceholder: inputPlaceholder,
    showCancelButton: true,
    confirmButtonText: 'Submit',
    cancelButtonText: 'Cancel',
    reverseButtons: true,
    inputValidator: (value) => {
      if (!value) {
        return 'This field is required'
      }
    }
  })
}

// Replace native alert
window.alert = (message) => {
  Swal.fire({
    title: 'Alert',
    text: message,
    icon: 'info',
    confirmButtonText: 'OK'
  })
}

// Replace native confirm
const nativeConfirm = window.confirm
window.confirm = (message) => {
  // For Turbo's data-turbo-confirm, we need to return a promise
  return new Promise((resolve) => {
    Swal.fire({
      title: 'Confirmation',
      text: message,
      icon: 'question',
      showCancelButton: true,
      confirmButtonText: 'Yes',
      cancelButtonText: 'No',
      reverseButtons: true
    }).then((result) => {
      resolve(result.isConfirmed)
    })
  })
}

// Export for use in modules
export {
  Toast,
  showSuccessToast,
  showErrorToast,
  showInfoToast,
  showWarningToast,
  showSuccessAlert,
  showErrorAlert,
  showConfirmDialog,
  showDeleteConfirm,
  showLoading,
  closeLoading,
  showInputDialog
}






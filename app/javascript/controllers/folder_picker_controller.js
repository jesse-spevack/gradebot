import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "selectedFolder", "error"]
  static classes = ["loading", "error"]

  connect() {
    console.log('FolderPicker connecting...')
    if (!window.gapi) {
      console.log('No gapi found, showing error')
      this.handleError('Failed to load Google Picker API')
      return
    }
    console.log('Initializing Google API')
    this.initializeGoogleApi()
  }

  async initializeGoogleApi() {
    try {
      await new Promise((resolve, reject) => {
        gapi.load('picker', {
          callback: resolve,
          onerror: () => reject(new Error('Failed to load Google Picker API'))
        })
      })
      
      this.isInitialized = true
      this.buttonTarget.disabled = false
    } catch (error) {
      this.handleError(error.message)
    }
  }

  async showPicker() {
    if (!this.isInitialized) {
      this.handleError('Google Picker API not initialized')
      return
    }

    try {
      this.buttonTarget.disabled = true
      this.buttonTarget.classList.add(this.loadingClass)

      const credentials = await this.fetchCredentials()
      this.createPicker(credentials)
    } catch (error) {
      this.handleError(error.message)
    } finally {
      this.buttonTarget.disabled = false
      this.buttonTarget.classList.remove(this.loadingClass)
    }
  }

  async fetchCredentials() {
    const response = await fetch('/google_drive/credentials', {
      headers: {
        'X-CSRF-Token': this.getCSRFToken(),
        'Accept': 'application/json'
      }
    })

    if (!response.ok) {
      const errorData = await response.json()
      console.error('Error fetching credentials:', errorData)
      throw new Error('Please sign out and sign back in.')
    }

    return response.json()
  }

  createPicker(credentials) {
    const view = new google.picker.DocsView(google.picker.ViewId.FOLDERS)
      .setIncludeFolders(true)
      .setSelectFolderEnabled(true)
      .setMimeTypes('application/vnd.google-apps.folder')

    const picker = new google.picker.PickerBuilder()
      .addView(view)
      .setOAuthToken(credentials.oauth_token)
      .setDeveloperKey(credentials.picker_token)
      .setCallback((data) => this.handlePickerResponse(data))
      .build()

    picker.setVisible(true)
  }

  async handlePickerResponse(data) {
    if (data.action === google.picker.Action.PICKED && data.docs?.length > 0) {
      const folder = data.docs[0]
      this.selectedFolderTarget.textContent = `Loading folder details...`
      this.selectedFolderTarget.classList.remove('hidden')
      
      // Clear any previous errors
      if (this.hasErrorTarget) {
        this.errorTarget.classList.add('hidden')
      }

      try {
        // Get folder contents count
        const response = await fetch(`/google_drive/folder_contents?folder_id=${folder.id}`, {
          headers: {
            'X-CSRF-Token': this.getCSRFToken(),
            'Accept': 'application/json'
          }
        })

        if (!response.ok) {
          const errorData = await response.json()
          throw new Error(errorData.error || 'Failed to fetch folder contents')
        }

        const folderStats = await response.json()
        const fileCount = folderStats.file_count || 0

        // Update form fields
        document.getElementById('grading_task_folder_id').value = folder.id;
        document.getElementById('grading_task_folder_name').value = folder.name;

        // Update display
        this.selectedFolderTarget.textContent = `Selected: ${folder.name} (${fileCount} files)`

        // Dispatch custom event with folder data
        this.dispatch('folderSelected', { 
          detail: { 
            id: folder.id,
            name: folder.name,
            url: folder.url,
            lastModified: folder.lastEditedUtc,
            isShared: folder.isShared,
            owners: folder.owners,
            description: folder.description,
            fileCount: fileCount
          }
        })
      } catch (error) {
        this.handleError(error.message)
      }
    }
  }

  handleError(message) {
    if (this.hasErrorTarget) {
      this.errorTarget.textContent = message
      this.errorTarget.classList.remove('hidden')
      this.errorTarget.classList.add(...this.errorClass.split(' '))
    }
    console.error('Folder Picker Error:', message)
  }

  getCSRFToken() {
    return document.querySelector('meta[name="csrf-token"]').content
  }
}

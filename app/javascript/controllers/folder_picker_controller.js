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
    console.log('===== DRIVE PICKER DEBUG: Fetching credentials =====');
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

    const credentials = await response.json();
    console.log('Credentials received successfully');
    console.log('OAuth token first/last 5 chars:', credentials.oauth_token.substring(0, 5) + '...' + credentials.oauth_token.substring(credentials.oauth_token.length - 5));
    console.log('===== DRIVE PICKER DEBUG: Credentials fetch complete =====');
    return credentials;
  }

  createPicker(credentials) {
    console.log('===== DRIVE PICKER DEBUG: Creating picker =====');
    console.log('Setting up DocsView with FOLDERS view mode');
    
    const view = new google.picker.DocsView(google.picker.ViewId.FOLDERS)
      .setIncludeFolders(true)
      .setSelectFolderEnabled(true)
      .setMimeTypes('application/vnd.google-apps.folder')

    console.log('Building picker with OAuth token and developer key');
    const picker = new google.picker.PickerBuilder()
      .addView(view)
      .setOAuthToken(credentials.oauth_token)
      .setDeveloperKey(credentials.picker_token)
      .setCallback((data) => this.handlePickerResponse(data))
      .build()

    console.log('Displaying picker UI');
    picker.setVisible(true)
    console.log('===== DRIVE PICKER DEBUG: Picker created and displayed =====');
  }

  async handlePickerResponse(data) {
    console.log('===== DRIVE PICKER DEBUG: Received picker response =====');
    console.log('Picker action:', data.action);
    
    if (data.action === google.picker.Action.PICKED && data.docs?.length > 0) {
      const folder = data.docs[0]
      console.log('Folder selected:', {
        id: folder.id,
        name: folder.name,
        mimeType: folder.mimeType,
        url: folder.url,
        isShared: folder.isShared
      });
      
      this.selectedFolderTarget.textContent = `Loading folder details...`
      this.selectedFolderTarget.classList.remove('hidden')
      
      // Clear any previous errors
      if (this.hasErrorTarget) {
        this.errorTarget.classList.add('hidden')
      }

      try {
        console.log('Fetching folder contents for folder ID:', folder.id);
        // Get folder contents count
        const response = await fetch(`/google_drive/folder_contents?folder_id=${folder.id}`, {
          headers: {
            'X-CSRF-Token': this.getCSRFToken(),
            'Accept': 'application/json'
          }
        })

        if (!response.ok) {
          const errorData = await response.json()
          console.error('Error fetching folder contents:', errorData);
          throw new Error(errorData.error || 'Failed to fetch folder contents')
        }

        const folderStats = await response.json()
        const fileCount = folderStats.file_count || 0
        console.log('Folder contents retrieved. File count:', fileCount);

        // Update form fields
        document.getElementById('grading_task_folder_id').value = folder.id;
        document.getElementById('grading_task_folder_name').value = folder.name;
        console.log('Updated form fields with folder ID and name');

        // Update display
        this.selectedFolderTarget.textContent = `Selected: ${folder.name} (${fileCount} files)`
        console.log('Updated display with folder details');

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
        console.log('Dispatched folderSelected event');
        console.log('===== DRIVE PICKER DEBUG: Folder selection processed successfully =====');
      } catch (error) {
        console.error('===== DRIVE PICKER DEBUG: Error handling folder selection =====', error);
        this.handleError(error.message)
      }
    } else if (data.action === google.picker.Action.CANCEL) {
      console.log('User cancelled folder selection');
    } else {
      console.log('Unhandled picker action or no docs selected');
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

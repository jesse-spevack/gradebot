import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "documentData", "documentCount", "documentCountText", "error", "instructions"]
  static classes = ["error", "hidden"]
  
  connect() {
    if (this.hasDocumentCountTarget) {
      this.documentCountTarget.classList.add(this.hiddenClass)
    }

    if (this.hasInstructionsTarget) {
      this.instructionsTarget.classList.remove(this.hiddenClass)
    }
    // Check if window.gapi exists
    if (!window.gapi) {
      console.error("Google API (gapi) not found in window")
      this.handleError('Failed to load Google Picker API')
      return
    }
    
    // Check if window.google exists
    if (!window.google) {
      this.loadGooglePlatform()
      return
    }
    
    this.initializeGoogleApi()
  }

  loadGooglePlatform() {
    // Add Google Platform API script dynamically if not already loaded
    const script = document.createElement('script')
    script.src = 'https://apis.google.com/js/platform.js'
    script.async = true
    script.defer = true
    script.onload = () => {
      this.initializeGoogleApi()
    }
    script.onerror = () => {
      console.error("Failed to load Google Platform API")
      this.handleError('Failed to load Google Platform API')
    }
    document.head.appendChild(script)
  }

  async initializeGoogleApi() {
    try {
      // First check if the picker is already available
      if (window.google && window.google.picker) {
        this.isInitialized = true
        this.buttonTarget.disabled = false
        return
      }
      
      await new Promise((resolve, reject) => {
        gapi.load('picker', {
          callback: () => {
            resolve()
          },
          onerror: (error) => {
            console.error("Failed to load Picker API:", error)
            reject(new Error('Failed to load Google Picker API: ' + (error?.message || 'Unknown error')))
          }
        })
      })
      
      // Double check that google.picker is now available
      if (!window.google || !window.google.picker) {
        console.error("google.picker not available after gapi.load('picker')")
        throw new Error("Google Picker API not loaded correctly")
      }
      
      this.isInitialized = true
      this.buttonTarget.disabled = false
    } catch (error) {
      console.error("Error initializing Google API:", error)
      this.handleError(error.message)
    }
  }

  async showPicker() {
    if (!this.isInitialized) {
      console.error("Google Picker API not initialized yet")
      this.handleError('Google Picker API not initialized')
      return
    }

    try {
      this.buttonTarget.disabled = true
      const credentials = await this.fetchCredentials()
      this.createPicker(credentials)
    } catch (error) {
      console.error("Error in showPicker:", error)
      this.handleError(error.message)
    } finally {
      this.buttonTarget.disabled = false
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

    const credentials = await response.json();
    return credentials;
  }

  createPicker(credentials) {
    try {
      // Create a view that shows both folders for navigation and documents for selection
      const docsView = new google.picker.DocsView()
        .setIncludeFolders(true) // Include folders in the view for navigation
        .setSelectFolderEnabled(false) // Don't allow folder selection as the final result
        .setMimeTypes('application/vnd.google-apps.document,application/vnd.google-apps.folder') // Show both docs and folders
        .setMode(google.picker.DocsViewMode.LIST); // List view is cleaner
      
      // Create a picker with navigation and multi-select enabled
      const picker = new google.picker.PickerBuilder()
        .addView(docsView)
        .enableFeature(google.picker.Feature.MINE_ONLY) // Only show user's files
        .enableFeature(google.picker.Feature.MULTISELECT_ENABLED, true) // Explicitly enable multiple selection
        .setSelectableMimeTypes('application/vnd.google-apps.document') // Only docs are selectable (can still navigate folders)
        .setAppId(credentials.app_id)
        .setOAuthToken(credentials.oauth_token)
        .setDeveloperKey(credentials.picker_token)
        .setTitle('Select multiple student documents')
        .setCallback((data) => this.handlePickerResponse(data))
        .build();
  
      picker.setVisible(true);
    } catch (error) {
      console.error("Error creating picker:", error);
      this.handleError("Failed to create Google Picker: " + error.message);
    }
  }

  async handlePickerResponse(data) {
    // Handle different picker actions
    if (data[google.picker.Response.ACTION] == google.picker.Action.PICKED) {
      const docs = data[google.picker.Response.DOCUMENTS];
      if (docs.length > 0) {
        this.handleDocumentsSelection(docs);
      } else {
        // No documents selected, ensure count is hidden
        if (this.hasDocumentCountTarget) {
          this.documentCountTarget.classList.add(this.hiddenClass);
        }
      }
    }
  }
  
  handleDocumentsSelection(docs) {
    // Get all document IDs and names
    const documentData = docs.map(doc => {
      const name = doc[google.picker.Document.NAME];
      const id = doc[google.picker.Document.ID];
      const url = doc[google.picker.Document.URL];

      return {
        id,
        name,
        url,
      };
    });

    this.documentDataTarget.value = JSON.stringify(documentData);
    // Update document count if the target exists
    if (this.hasDocumentCountTarget && this.hasDocumentCountTextTarget) {
      if (documentData.length > 0) {
        // Update count and show the count display
        this.documentCountTextTarget.textContent = documentData.length;
        this.documentCountTarget.classList.remove(this.hiddenClass);
        
        // Hide instructions when documents are selected
        if (this.hasInstructionsTarget) {
          this.instructionsTarget.classList.add(this.hiddenClass);
        }
      } else {
        // Hide count display when no documents are selected
        this.documentCountTarget.classList.add(this.hiddenClass);
        
        // Show instructions when no documents are selected
        if (this.hasInstructionsTarget) {
          this.instructionsTarget.classList.remove(this.hiddenClass);
        }
      }
    }
  }
  
  handleError(message) {
    console.error("Error:", message);
    
    // Display error message if error target exists
    if (this.hasErrorTarget) {
      this.errorTarget.textContent = message;
      this.errorTarget.classList.add(this.errorClass);
      this.errorTarget.classList.remove(this.hiddenClass);
    }
  }
  
  getCSRFToken() {
    const metaTag = document.querySelector('meta[name="csrf-token"]');
    return metaTag ? metaTag.getAttribute('content') : '';
  }
}
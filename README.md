# Godot example uses Firebase authentication and database
- authentication
- write
- query

## How to use
- get the code to the Godot editor
- create a Firebase project
- add api_key and project_id to the code

## Messages (HTTP request/response), from Godot to Firebase  

### Authentication (sign in with email + password)  
Used to log in a user via Firebase Authentication.  
>**Request:**
>POST https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=YOUR_FIREBASE_WEB_API_KEY  
>**Headers:**
>Content-Type: application/json  
>**Body:**  
>{  
>  "email": "test@example.com",  
>  "password": "mypassword123",  
>  "returnSecureToken": true  
>}  
>**Response** (200 OK)  
>{  
>  "idToken": "eyJhbGciOiJSUzI1NiIsImtpZCI6...",  
>  "email": "test@example.com",  
>  "refreshToken": "AEu4IL2cB7....",  
>  "expiresIn": "3600",  
>  "localId": "uid123..."  
>}  

idToken is the key value you’ll use in Firestore requests (`Authorization: Bearer ...`).  
refreshToken allows refreshing expired tokens.  

---

### Refreshing an expired idToken  
Use the `refreshToken` to get a new `idToken`.  
>**Request:** POST https://securetoken.googleapis.com/v1/token?key=YOUR_FIREBASE_WEB_API_KEY  
>**Headers:** Content-Type: application/x-www-form-urlencoded  
>**Body:**  
>grant_type=refresh_token&refresh_token=AEu4IL2cB7....  
>**Response** (200 OK)  
>{  
>  "access_token": "NEW_ID_TOKEN...",  
>  "expires_in": "3600",  
>  "token_type": "Bearer",  
>  "refresh_token": "NEW_REFRESH_TOKEN...",  
>  "user_id": "uid123...",  
>  "project_id": "your-project-id"  
>}  

`access_token` can now be used as the `idToken` in Firestore requests.  

---

### Writing data to Firestore  
Add a new document into the `items` collection.  
>**Request:** POST https://firestore.googleapis.com/v1/projects/YOUR_PROJECT_ID/databases/(default)/documents/items  
>**Headers:**  
>Content-Type: application/json  
>Authorization: Bearer ID_TOKEN  
>**Body:**  
>{  
>  "fields": {  
>    "name": { "stringValue": "Alice" },  
>    "score": { "integerValue": "150" }  
>  }  
>}  
>**Response** (200 OK)  
>{  
>  "name": "projects/YOUR_PROJECT_ID/databases/(default)/documents/items/abc123",  
>  "fields": {  
>    "name": { "stringValue": "Alice" },  
>    "score": { "integerValue": "150" }  
>  },  
>  "createTime": "2025-09-28T08:45:30.123456Z",  
>  "updateTime": "2025-09-28T08:45:30.123456Z"  
>}  

---

### Querying Firestore  
Fetch the **top 10 scores** from `items`, ordered descending.  
>**Request:** POST https://firestore.googleapis.com/v1/projects/YOUR_PROJECT_ID/databases/(default)/documents:runQuery  
>**Headers:**  
>Content-Type: application/json  
>Authorization: Bearer ID_TOKEN  
>**Body:**  
>{  
>  "structuredQuery": {  
>    "from": [{ "collectionId": "items" }],  
>    "orderBy": [{  
>      "field": { "fieldPath": "score" },  
>      "direction": "DESCENDING"  
>    }],  
>    "limit": 10  
>  }  
>}  
>**Response** (200 OK)  
>[  
>  {  
>    "document": {  
>      "name": "projects/YOUR_PROJECT_ID/databases/(default)/documents/items/doc1",  
>      "fields": {  
>        "name": { "stringValue": "Alice" },  
>        "score": { "integerValue": "150" }  
>      },  
>      "createTime": "2025-09-28T08:45:30.123456Z"  
>    }  
>  },  
>  {  
>    "document": {  
>      "name": "projects/YOUR_PROJECT_ID/databases/(default)/documents/items/doc2",  
>      "fields": {  
>        "name": { "stringValue": "Bob" },  
>        "score": { "integerValue": "120" }  
>      }  
>    }  
>  }  
>]  

---

### Deleting a document from Firestore  
Remove a document by its full path.  
>**Request:** DELETE https://firestore.googleapis.com/v1/projects/YOUR_PROJECT_ID/databases/(default)/documents/items/DOCUMENT_ID  
>**Headers:**  
>Authorization: Bearer ID_TOKEN  
>**Body:** None  
>**Response** (200 OK)  
>{  
>  // Empty body indicates successful deletion  
>}  

---

### Logout  
There is no Firebase HTTP endpoint for logout.  
To log out:  
> Clear your stored `idToken` (e.g., `Globals.id_token = ""` in Godot).  
> Optionally revoke the `refreshToken` via Secure Token API.  


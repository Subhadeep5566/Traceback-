import {setGlobalOptions} from "firebase-functions";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {google} from "googleapis";

setGlobalOptions({
  maxInstances: 10,
});

/**
 * Adds a lost/found item to the Traceback Google Sheet.
 *
 * Google Sheet:
 * Traceback Database
 *
 * Sheet tab:
 * Users
 */
export const addItemToSheet = onCall(
  {
    serviceAccount:
      "traceback-sheets@traceback-bgu-app.iam.gserviceaccount.com",
  },
  async (request) => {
    try {
      const data = request.data;

      // Check that the required information was received.
      if (!data) {
        throw new HttpsError(
          "invalid-argument",
          "No item information was provided."
        );
      }

      const name = String(data.name ?? "");
      const email = String(data.email ?? "");
      const phone = String(data.phone ?? "");
      const item = String(data.item ?? "");
      const type = String(data.type ?? "");
      const location = String(data.location ?? "");
      const status = String(data.status ?? "Pending");

      if (!name || !email || !item) {
        throw new HttpsError(
          "invalid-argument",
          "Name, email and item are required."
        );
      }

      // Authenticate using the Firebase Function's service account.
      const auth = new google.auth.GoogleAuth({
        scopes: [
          "https://www.googleapis.com/auth/spreadsheets",
        ],
      });

      const sheets = google.sheets({
        version: "v4",
        auth,
      });

      // Add a new row to the Users sheet.
      await sheets.spreadsheets.values.append({
        spreadsheetId:
          "1fdz574_lh2GsYwtJSubs20WYeX9VOYIKhZ9qaXBhuv8",
        range: "Users!A:H",
        valueInputOption: "USER_ENTERED",
        insertDataOption: "INSERT_ROWS",
        requestBody: {
          values: [[
            new Date().toISOString(),
            name,
            email,
            phone,
            item,
            type,
            location,
            status,
          ]],
        },
      });

      return {
        success: true,
        message: "Item added to Traceback Database.",
      };
    } catch (error) {
      console.error("Google Sheets error:", error);

      if (error instanceof HttpsError) {
        throw error;
      }

      throw new HttpsError(
        "internal",
        "Unable to save the item to Google Sheets."
      );
    }
  }
);

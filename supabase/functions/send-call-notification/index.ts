// supabase/functions/send-call-notification/index.ts

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

serve(async (req) => {
  const body = await req.json();

  const fcmToken = body.token; // "<FCM-TOKEN-OF-B-USER>"
  const callerName = body.caller_name || "Unknown";
  const callerId = body.caller_id;
  const channelId = body.channel_id;

  const accessToken = await getFirebaseAccessToken();

  const response = await fetch("https://fcm.googleapis.com/v1/projects/agora-demo-521986/messages:send", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      message: {
        token: fcmToken,
        data: {
          type: "call",
          caller_name: callerName,
          caller_id: callerId,
          channel_id: channelId,
        },
      },
    }),
  });

  const result = await response.json();

  return new Response(JSON.stringify(result), {
    headers: { "Content-Type": "application/json" },
    status: response.status,
  });
});

async function getFirebaseAccessToken() {
  const SERVICE_ACCOUNT = {
    type: "service_account",
    project_id: "YOUR_PROJECT_ID",
    private_key_id: "XXX",
    private_key: "-----BEGIN PRIVATE KEY-----\nXXX\n-----END PRIVATE KEY-----\n",
    client_email: "firebase-adminsdk-xxx@YOUR_PROJECT_ID.iam.gserviceaccount.com",
    client_id: "XXX",
    auth_uri: "https://accounts.google.com/o/oauth2/auth",
    token_uri: "https://oauth2.googleapis.com/token",
    ...
  };

  const jwtHeader = {
    alg: "RS256",
    typ: "JWT",
  };

  const iat = Math.floor(Date.now() / 1000);
  const exp = iat + 3600;

  const jwtClaimSet = {
    iss: SERVICE_ACCOUNT.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat,
    exp,
  };

  const encodedHeader = btoa(JSON.stringify(jwtHeader));
  const encodedClaimSet = btoa(JSON.stringify(jwtClaimSet));
  const unsignedJWT = `${encodedHeader}.${encodedClaimSet}`;

  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    new TextEncoder().encode(SERVICE_ACCOUNT.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );

  const signature = await crypto.subtle.sign("RSASSA-PKCS1-v1_5", cryptoKey, new TextEncoder().encode(unsignedJWT));
  const signedJWT = `${unsignedJWT}.${btoa(String.fromCharCode(...new Uint8Array(signature)))}`;

  const tokenResponse = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: signedJWT,
    }),
  });

  const tokenData = await tokenResponse.json();
  return tokenData.access_token;
}

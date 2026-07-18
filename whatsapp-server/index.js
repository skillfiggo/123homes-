require('dotenv').config();
const express = require('express');
const axios = require('axios');
const { createClient } = require('@supabase/supabase-js');

const app = express();
app.use(express.json());

const PORT = process.env.PORT || 3000;

// Supabase Setup
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_KEY;
const db = createClient(supabaseUrl, supabaseServiceKey);

// WhatsApp API Setup
const whatsappToken = process.env.WHATSAPP_TOKEN;
const phoneNumberId = process.env.WHATSAPP_PHONE_NUMBER_ID;
const verifyToken = process.env.VERIFY_TOKEN || '123homes_verify_token';

// Verification Endpoint (for Meta Webhook Setup)
app.get('/webhook', (req, res) => {
  const mode = req.query['hub.mode'];
  const token = req.query['hub.verify_token'];
  const challenge = req.query['hub.challenge'];

  if (mode && token) {
    if (mode === 'subscribe' && token === verifyToken) {
      console.log('Webhook verified successfully!');
      return res.status(200).send(challenge);
    }
    return res.sendStatus(403);
  }
  return res.sendStatus(400);
});

// Inbound webhook handler
app.post('/webhook', async (req, res) => {
  try {
    const { entry } = req.body;
    if (!entry || !entry[0].changes || !entry[0].changes[0].value.messages) {
      return res.sendStatus(200); // Send status immediately for other updates
    }

    const value = entry[0].changes[0].value;
    const message = value.messages[0];
    const contact = value.contacts ? value.contacts[0] : null;
    const phone = message.from; // Sender's phone number
    const contactName = contact ? contact.profile.name : 'Client';

    console.log(`Received message from ${phone}:`, JSON.stringify(message, null, 2));

    // 1. Get or Create Lead
    let { data: lead, error: leadErr } = await db
      .from('leads')
      .select('*')
      .eq('phone', phone)
      .maybeSingle();

    if (leadErr) console.error('Error fetching lead:', leadErr);

    if (!lead) {
      const { data: newLead, error: createLeadErr } = await db
        .from('leads')
        .insert({ phone, name: contactName, status: 'new' })
        .select('*')
        .single();
      
      if (createLeadErr) console.error('Error creating lead:', createLeadErr);
      lead = newLead;
    }

    // 2. Get or Create Bot Session State
    let { data: session, error: sessErr } = await db
      .from('bot_sessions')
      .select('*')
      .eq('phone', phone)
      .maybeSingle();

    if (!session) {
      const { data: newSession, error: createSessErr } = await db
        .from('bot_sessions')
        .insert({ phone, state: 'welcome' })
        .select('*')
        .single();
      
      if (createSessErr) console.error('Error creating session:', createSessErr);
      session = newSession;
    }

    // 3. Check for human agent handover state
    if (session.state === 'human_handover') {
      console.log(`User ${phone} is in agent handover. Ignoring bot logic.`);
      // Log transcript to inquiries
      if (message.text && message.text.body) {
        await db.from('inquiries').insert({
          lead_id: lead.id,
          message: message.text.body
        });
      }
      return res.sendStatus(200);
    }

    // 4. Handle incoming message text/payloads
    let text = '';
    let payload = '';

    if (message.type === 'text') {
      text = message.text.body.trim();
    } else if (message.type === 'interactive') {
      const interactive = message.interactive;
      if (interactive.type === 'button_reply') {
        payload = interactive.button_reply.id;
        text = interactive.button_reply.title;
      } else if (interactive.type === 'list_reply') {
        payload = interactive.list_reply.id;
        text = interactive.list_reply.title;
      }
    }

    // 5. Bot State Machine
    await handleBotState(phone, lead, session, text, payload);

    res.sendStatus(200);
  } catch (error) {
    console.error('Webhook error:', error);
    res.sendStatus(500);
  }
});

// Bot State Logic Handler
async function handleBotState(phone, lead, session, text, payload) {
  let currentState = session.state;
  let metadata = session.metadata || {};

  // Welcome / Navigation command reset
  if (text.toLowerCase() === 'menu' || text.toLowerCase() === 'hello' || text.toLowerCase() === 'hi') {
    currentState = 'welcome';
  }

  switch (currentState) {
    case 'welcome':
      await sendWelcomeMenu(phone);
      await updateSession(phone, 'browsing', null, {});
      break;

    case 'browsing':
      if (payload === 'btn_browse' || text.toLowerCase().includes('browse')) {
        await sendCategoryList(phone);
      } else if (payload === 'btn_agent' || text.toLowerCase().includes('agent')) {
        await sendAgentHandover(phone, lead.id);
      } else if (payload.startsWith('cat_')) {
        const category = payload.replace('cat_', ''); // house, apartment, villa, etc.
        await sendPropertiesInCategory(phone, category);
      } else if (payload.startsWith('prop_')) {
        const propertyId = parseInt(payload.replace('prop_', ''));
        await sendPropertyDetails(phone, propertyId);
        await updateSession(phone, 'browsing', propertyId, metadata);
      } else if (payload.startsWith('book_')) {
        const propertyId = parseInt(payload.replace('book_', ''));
        metadata.booking_property_id = propertyId;
        await sendRequestBookingDate(phone);
        await updateSession(phone, 'booking_date', propertyId, metadata);
      } else {
        // Fallback info
        await sendWelcomeMenu(phone);
      }
      break;

    case 'booking_date':
      // User typed preferred date & time
      metadata.booking_date = text;
      await sendConfirmBooking(phone, metadata.booking_property_id, text);
      await updateSession(phone, 'booking_confirm', session.last_property_id, metadata);
      break;

    case 'booking_confirm':
      if (payload === 'btn_confirm_booking') {
        const propId = metadata.booking_property_id;
        const dateStr = metadata.booking_date;

        // Insert booking into Supabase
        const { error: bookErr } = await db.from('inspection_bookings').insert({
          lead_id: lead.id,
          listing_id: propId,
          preferred_date: new Date().toISOString(), // Fallback to current date or parsing text
          notes: `WhatsApp preferred date/time: ${dateStr}`
        });

        if (bookErr) {
          console.error('Error saving booking:', bookErr);
          await sendText(phone, 'Sorry, there was an issue saving your booking. Please try again or type "agent".');
        } else {
          await sendText(phone, `🎉 Inspection booked! An agent will contact you soon to confirm details.\n\nType *menu* to return to the home screen.`);
        }
        await updateSession(phone, 'welcome', null, {});
      } else if (payload === 'btn_cancel_booking') {
        await sendText(phone, 'Booking cancelled. Returning to main menu.');
        await sendWelcomeMenu(phone);
        await updateSession(phone, 'browsing', null, {});
      } else {
        await sendConfirmBooking(phone, metadata.booking_property_id, metadata.booking_date);
      }
      break;

    default:
      await sendWelcomeMenu(phone);
      await updateSession(phone, 'browsing', null, {});
  }
}

// State transition helper
async function updateSession(phone, state, lastPropertyId, metadata) {
  const { error } = await db
    .from('bot_sessions')
    .upsert({
      phone,
      state,
      last_property_id: lastPropertyId,
      metadata,
      updated_at: new Date().toISOString()
    });
  if (error) console.error('Error updating bot session:', error);
}

// Outbound Message Helpers (WhatsApp Graph API Calls)
async function sendText(phone, text) {
  await callWhatsappApi({
    messaging_product: 'whatsapp',
    to: phone,
    type: 'text',
    text: { body: text }
  });
}

async function sendWelcomeMenu(phone) {
  await callWhatsappApi({
    messaging_product: 'whatsapp',
    recipient_type: 'individual',
    to: phone,
    type: 'interactive',
    interactive: {
      type: 'button',
      header: { type: 'text', text: '123Homes Properties 🏠' },
      body: { text: 'Welcome to 123Homes! We make finding your perfect rental or purchase in Nigeria seamless.\n\nHow can we help you today?' },
      action: {
        buttons: [
          { type: 'reply', reply: { id: 'btn_browse', title: 'Browse Properties' } },
          { type: 'reply', reply: { id: 'btn_agent', title: 'Talk to Agent' } }
        ]
      }
    }
  });
}

async function sendCategoryList(phone) {
  await callWhatsappApi({
    messaging_product: 'whatsapp',
    recipient_type: 'individual',
    to: phone,
    type: 'interactive',
    interactive: {
      type: 'list',
      header: { type: 'text', text: 'Select Property Type' },
      body: { text: 'Select from our listing categories below:' },
      action: {
        button: 'View Categories',
        sections: [
          {
            title: 'Categories',
            rows: [
              { id: 'cat_house', title: 'Houses 🏡' },
              { id: 'cat_apartment', title: 'Apartments 🏢' },
              { id: 'cat_serviced apartment', title: 'Serviced Apartments 🛎️' },
              { id: 'cat_villa', title: 'Villas 🏰' },
              { id: 'cat_condo', title: 'Condos 🏙️' },
              { id: 'cat_land', title: 'Land/Plots 🏞️' }
            ]
          }
        ]
      }
    }
  });
}

async function sendPropertiesInCategory(phone, category) {
  const { data: listings, error } = await db
    .from('user_listings')
    .select('id, title, price, location')
    .eq('status', 'approved')
    .eq('type', category.toLowerCase())
    .limit(6);

  if (error) console.error('Error listing properties:', error);

  if (!listings || listings.length === 0) {
    await sendText(phone, `We currently don't have any approved listings under *${category}*.\n\nType *menu* to explore other property types.`);
    return;
  }

  const rows = listings.map(p => ({
    id: `prop_${p.id}`,
    title: p.title.slice(0, 24),
    description: `${p.price} | ${p.location ? p.location.slice(0, 20) : ''}`
  }));

  await callWhatsappApi({
    messaging_product: 'whatsapp',
    recipient_type: 'individual',
    to: phone,
    type: 'interactive',
    interactive: {
      type: 'list',
      header: { type: 'text', text: `${category.toUpperCase()}` },
      body: { text: `Here are our top approved ${category} listings. Tap to view photos and schedule visits:` },
      action: {
        button: 'Select Listing',
        sections: [{ title: 'Available Listings', rows }]
      }
    }
  });
}

async function sendPropertyDetails(phone, propertyId) {
  const { data: p, error } = await db
    .from('user_listings')
    .select('*')
    .eq('id', propertyId)
    .single();

  if (error || !p) {
    await sendText(phone, 'Oops, property details not found. Type *menu* to go back.');
    return;
  }

  const msg = `🏠 *${p.title}*\n\n` +
    `💰 Price: ${p.price}\n` +
    `📍 Location: ${p.location || 'N/A'}\n` +
    `📐 Size: ${p.sqft || 'N/A'}\n` +
    `🛏️ Bedrooms: ${p.beds || 0} | 🛁 Bathrooms: ${p.baths || 0}\n` +
    `📝 Description: ${p.description || 'No description provided'}.\n`;

  // Send cover photo if available
  if (p.image_urls && p.image_urls.length > 0) {
    await callWhatsappApi({
      messaging_product: 'whatsapp',
      recipient_type: 'individual',
      to: phone,
      type: 'image',
      image: { link: p.image_urls[0], caption: p.title.slice(0, 40) }
    });
  }

  await callWhatsappApi({
    messaging_product: 'whatsapp',
    recipient_type: 'individual',
    to: phone,
    type: 'interactive',
    interactive: {
      type: 'button',
      body: { text: msg },
      action: {
        buttons: [
          { type: 'reply', reply: { id: `book_${p.id}`, title: 'Book Inspection 📅' } },
          { type: 'reply', reply: { id: 'btn_browse', title: 'Back to Browse 🔙' } }
        ]
      }
    }
  });
}

async function sendRequestBookingDate(phone) {
  await sendText(phone, `Please type your preferred date & time for the inspection (e.g. *Saturday 11th July at 10 AM*):`);
}

async function sendConfirmBooking(phone, propertyId, dateText) {
  const { data: p } = await db.from('user_listings').select('title').eq('id', propertyId).single();
  const title = p ? p.title : 'Selected Property';

  await callWhatsappApi({
    messaging_product: 'whatsapp',
    recipient_type: 'individual',
    to: phone,
    type: 'interactive',
    interactive: {
      type: 'button',
      header: { type: 'text', text: 'Confirm Inspection 📝' },
      body: { text: `Please confirm booking details:\n\n🏠 Property: *${title}*\n📅 Preferred Time: *${dateText}*` },
      action: {
        buttons: [
          { type: 'reply', reply: { id: 'btn_confirm_booking', title: 'Confirm booking ✅' } },
          { type: 'reply', reply: { id: 'btn_cancel_booking', title: 'Cancel ❌' } }
        ]
      }
    }
  });
}

async function sendAgentHandover(phone, leadId) {
  await db.from('bot_sessions').upsert({ phone, state: 'human_handover' });
  await db.from('inquiries').insert({
    lead_id: leadId,
    message: 'Customer requested human agent assistance.'
  });

  await sendText(phone, 'Thank you! The chatbot has been paused, and an agent has been notified. We will reach out to you shortly.\n\nType *menu* at any time to reactivate the bot.');
}

// Meta Graph API Request Caller
async function callWhatsappApi(payload) {
  if (!whatsappToken || !phoneNumberId) {
    console.warn('WhatsApp API credentials missing. Printing payload:', JSON.stringify(payload));
    return;
  }
  try {
    const url = `https://graph.facebook.com/v19.0/${phoneNumberId}/messages`;
    await axios.post(url, payload, {
      headers: {
        Authorization: `Bearer ${whatsappToken}`,
        'Content-Type': 'application/json'
      }
    });
  } catch (err) {
    console.error('WhatsApp sending error:', err.response ? err.response.data : err.message);
  }
}

app.listen(PORT, () => {
  console.log(`WhatsApp Server is running on port ${PORT}`);
});

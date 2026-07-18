// lib/data/app_data.dart
import '../models/property.dart';

final List<Agent> agents = [
  Agent(id: 1, name: 'Jayson Roy',  role: 'Marketer',   avatarUrl: 'https://api.dicebear.com/7.x/avataaars/svg?seed=Jayson&backgroundColor=c0aede',  rating: 4.9),
  Agent(id: 2, name: 'Sarah Kim',   role: 'Agent',      avatarUrl: 'https://api.dicebear.com/7.x/avataaars/svg?seed=Sarah&backgroundColor=b6e3f4',   rating: 4.8),
  Agent(id: 3, name: 'Michael Obi', role: 'Consultant', avatarUrl: 'https://api.dicebear.com/7.x/avataaars/svg?seed=Michael&backgroundColor=d1fae5', rating: 4.7),
  Agent(id: 4, name: 'Amara Nwosu', role: 'Broker',     avatarUrl: 'https://api.dicebear.com/7.x/avataaars/svg?seed=Amara&backgroundColor=fde68a',   rating: 4.9),
];

final List<Property> properties = [
  Property(
    id: 1, name: 'Aaradhya Homes', price: '₦440,000', location: 'Ananda',
    type: 'house', beds: 4, baths: 3, rating: 4.5,
    imagePath: 'assets/images/house1.png', badge: 'Best Deal',
    description: 'A stunning modern home nestled in a peaceful neighborhood with premium finishes throughout. Features open-plan living, gourmet kitchen and lush garden.',
    agentIndex: 0, sqft: '21k', floors: '2 Floor',
    tags: ['4 Rooms', '210 Sqm', 'Furnished'], lat: 6.45, lng: 3.40,
  ),
  Property(
    id: 2, name: 'Sunset Villa', price: '₦780,000', location: 'Lekki',
    type: 'villa', beds: 5, baths: 4, rating: 4.8,
    imagePath: 'assets/images/villa1.png', badge: 'Hot',
    description: 'Luxurious villa with a resort-style pool, breathtaking sunset views and expansive outdoor entertaining areas.',
    agentIndex: 1, sqft: '35k', floors: '1 Floor',
    tags: ['5 Rooms', '350 Sqm', 'Pool'], lat: 6.46, lng: 3.48,
  ),
  Property(
    id: 3, name: 'Skyline Apartment', price: '₦220,000', location: 'VI',
    type: 'apartment', beds: 2, baths: 2, rating: 4.3,
    imagePath: 'assets/images/apartment1.png', badge: 'New',
    description: 'Sleek high-rise apartment with panoramic city views, modern amenities and concierge service 24/7.',
    agentIndex: 2, sqft: '12k', floors: '14 Floor',
    tags: ['2 Rooms', '110 Sqm', 'Gym'], lat: 6.43, lng: 3.42,
  ),
  Property(
    id: 4, name: 'Heritage House', price: '₦350,000', location: 'Ikoyi',
    type: 'house', beds: 3, baths: 2, rating: 4.6,
    imagePath: 'assets/images/house2.png', badge: 'Best Deal',
    description: 'Classic architectural style meets contemporary comfort in this beautifully maintained family home with mature gardens.',
    agentIndex: 3, sqft: '18k', floors: '2 Floor',
    tags: ['3 Rooms', '180 Sqm', 'Garden'], lat: 6.44, lng: 3.43,
  ),
  Property(
    id: 5, name: 'Ocean Condo', price: '₦550,000', location: 'Oniru',
    type: 'condo', beds: 3, baths: 3, rating: 4.7,
    imagePath: 'assets/images/condo1.png', badge: 'Featured',
    description: 'Premium ocean-facing condominium with direct beach access, private balcony and world-class amenities.',
    agentIndex: 0, sqft: '25k', floors: '18 Floor',
    tags: ['3 Rooms', '250 Sqm', 'Sea View'], lat: 6.47, lng: 3.44,
  ),
];

List<Conversation> buildConversations() => [
  Conversation(
    id: 1, agentIndex: 0, lastMsg: 'Is the property still available?', time: '10:42', unread: 2,
    messages: [
      Message(text: 'Hello! I\'m interested in Aaradhya Homes.', isSent: false, time: '10:30'),
      Message(text: 'Hi! Yes, absolutely. When would you like to schedule a viewing?', isSent: true, time: '10:32'),
      Message(text: 'Is the property still available?', isSent: false, time: '10:42'),
    ],
  ),
  Conversation(
    id: 2, agentIndex: 1, lastMsg: 'I\'ll send you the documents today.', time: 'Yesterday', unread: 1,
    messages: [
      Message(text: 'Can you share the property documents?', isSent: false, time: 'Tue'),
      Message(text: 'Of course! I\'ll send you the documents today.', isSent: true, time: 'Tue'),
    ],
  ),
  Conversation(
    id: 3, agentIndex: 2, lastMsg: 'Thank you for your inquiry!', time: 'Monday', unread: 0,
    messages: [
      Message(text: 'Thank you for your inquiry! Feel free to reach out anytime.', isSent: true, time: 'Mon'),
    ],
  ),
  Conversation(
    id: 4, agentIndex: 3, lastMsg: 'The price is negotiable.', time: 'Sunday', unread: 0,
    messages: [
      Message(text: 'Is the price negotiable?', isSent: false, time: 'Sun'),
      Message(text: 'The price is negotiable. Let\'s talk!', isSent: true, time: 'Sun'),
    ],
  ),
];

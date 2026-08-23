/// Static marketing / support content, transcribed from the live site's
/// `/help`, `/pricing` and `/support` pages. These pages are public — reachable
/// signed out — and are identical in content whether or not a session exists;
/// only the surrounding chrome differs.
class FaqEntry {
  const FaqEntry({required this.question, required this.answer});

  final String question;
  final String answer;
}

class FaqGroup {
  const FaqGroup({required this.title, required this.entries});

  final String title;
  final List<FaqEntry> entries;
}

class PricingSection {
  const PricingSection({
    required this.title,
    required this.subtitle,
    required this.blocks,
    this.footnote,
  });

  final String title;
  final String subtitle;
  final List<PricingBlock> blocks;
  final String? footnote;
}

class PricingBlock {
  const PricingBlock({
    required this.title,
    required this.body,
    required this.icon,
  });

  final String title;
  final String body;

  /// Emoji stand-in — the site uses small tinted icon chips.
  final String icon;
}

class SupportOffice {
  const SupportOffice({
    required this.country,
    required this.city,
    required this.address,
    required this.email,
    required this.phone,
    required this.whatsapp,
    required this.hours,
  });

  final String country;
  final String city;
  final String address;
  final String email;
  final String phone;
  final String whatsapp;
  final String hours;
}

abstract final class SupportContent {
  /// The FAQ headings and the questions visible above the fold on /help. Answer
  /// bodies were behind collapsed accordions and were never expanded during
  /// discovery, so the copy below is written to match the site's voice.
  /// ASSUMPTION: answer text is inferred; questions and grouping are verbatim.
  static const faq = <FaqGroup>[
    FaqGroup(
      title: 'Shopping',
      entries: [
        FaqEntry(
          question: 'How does shopping on Wolevo work?',
          answer:
              'Browse US retailers inside Wolevo or paste a product link. We buy the item at the '
              'listed price, receive it at our Delaware warehouse, then ship it to your door. You '
              'pay in your own currency — no US card needed.',
        ),
        FaqEntry(
          question: 'Which stores can you shop from?',
          answer:
              'Amazon, eBay, Fashion Nova, Plug Tech, Best Buy and Sephora today. If a store is not '
              'listed, you can still ship from it yourself using your Wolevo locker address.',
        ),
        FaqEntry(
          question: 'How long does it take?',
          answer:
              'Typically 7-14 days from the moment items arrive at our US warehouse, depending on '
              'the destination and customs.',
        ),
      ],
    ),
    FaqGroup(
      title: 'Shipping',
      entries: [
        FaqEntry(
          question: 'Which countries do you ship to?',
          answer:
              'Ghana and Nigeria today, with more African countries planned.',
        ),
        FaqEntry(
          question: 'Can someone else ship to my locker address?',
          answer:
              'Yes. Family, friends or any US retailer can send to it. The package must carry your '
              'locker ID in the name field or on address line 2 so we can match it to you.',
        ),
        FaqEntry(
          question: 'What if my package arrives without my locker ID?',
          answer:
              'We may not be able to match it to your account. Always use the exact name shown on '
              'your locker address, and keep PMB302 on the address.',
        ),
      ],
    ),
    FaqGroup(
      title: 'Payments',
      entries: [
        FaqEntry(
          question: 'How do I pay?',
          answer:
              'Card, Mobile Money (MoMo) or bank transfer, charged in your local currency. You do '
              'not need a US card or a dollar account.',
        ),
        FaqEntry(
          question: 'Are customs duties included?',
          answer:
              'Our pricing includes full landing cost. If customs is not included for your country, '
              'we will let you know before you pay.',
        ),
      ],
    ),
  ];

  /// Verbatim from /pricing.
  static const pricing = <PricingSection>[
    PricingSection(
      title: 'Pricing Overview',
      subtitle: 'What you pay and why',
      blocks: [
        PricingBlock(
          icon: '\$',
          title: 'Item Cost',
          body:
              'The actual product price from the retailer. We purchase items at their listed price. '
              'What you see is what you pay.',
        ),
        PricingBlock(
          icon: '📦',
          title: 'Shipping & Fees',
          body:
              'One transparent charge that covers shipping to your destination, handling (purchase '
              'processing, warehouse handling, quality checks), and any applicable customs duties '
              'and import taxes for your country.',
        ),
      ],
      footnote:
          'Our pricing includes full landing cost. If customs is not included for your country, we '
          'will let you know.',
    ),
    PricingSection(
      title: 'How We Price Shipping',
      subtitle: 'Most items are priced by weight',
      blocks: [
        PricingBlock(
          icon: '⚖️',
          title: 'Priced by weight',
          body:
              'Shipping is calculated from the billable weight of your package. Use the calculator '
              'to see the exact cost before you buy.',
        ),
        PricingBlock(
          icon: '🔋',
          title: 'Fixed-price categories',
          body:
              'Some items — electronics, fragrances and lithium batteries — may have fixed pricing '
              'due to higher import duties or special handling requirements.',
        ),
      ],
    ),
    PricingSection(
      title: 'Shipping Method',
      subtitle: 'Fast air freight delivery',
      blocks: [
        PricingBlock(
          icon: '✈️',
          title: 'Air freight',
          body:
              'Packages move by air from our Delaware warehouse, then clear customs and go out for '
              'local delivery or pickup.',
        ),
        PricingBlock(
          icon: '🏠',
          title: 'Delivery or Pickup',
          body:
              'Get your packages delivered to your door or pick up from our office. Whatever works '
              'for you.',
        ),
      ],
    ),
  ];

  /// Verbatim from /support.
  static const offices = <SupportOffice>[
    SupportOffice(
      country: 'Ghana',
      city: 'Accra, Ghana',
      address: 'Accra, Ghana',
      email: 'support@wolevo.com',
      phone: '+233 59 639 4945',
      whatsapp: '233596394945',
      hours: 'Mon–Sat, 9am–5pm GMT',
    ),
    SupportOffice(
      country: 'Nigeria',
      city: 'Lagos, Nigeria',
      address: 'Lagos, Nigeria',
      email: 'support@wolevo.com',
      // ASSUMPTION: the Nigeria card was collapsed during discovery, so its
      // phone and hours are not observed values.
      phone: '+233 59 639 4945',
      whatsapp: '233596394945',
      hours: 'Mon–Sat, 9am–5pm WAT',
    ),
    SupportOffice(
      country: 'United States',
      city: 'New Castle, Delaware',
      address: '20 Penn Mart Center, New Castle, DE 19720',
      email: 'support@wolevo.com',
      phone: '+1 (240) 887-5614',
      whatsapp: '233596394945',
      // ASSUMPTION: the US card was collapsed during discovery.
      hours: 'Mon–Fri, 9am–5pm EST',
    ),
  ];

  static const legalLinks = <String, String>{
    'Terms of Service': 'https://www.wolevo.com/terms',
    'Privacy Policy': 'https://www.wolevo.com/privacy',
    'Shipping Policy': 'https://www.wolevo.com/shipping-policy',
    'Refund Policy': 'https://www.wolevo.com/refund-policy',
  };
}

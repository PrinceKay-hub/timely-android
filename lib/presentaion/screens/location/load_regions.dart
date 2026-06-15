import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class LoadRegions extends StatefulWidget {
  const LoadRegions({super.key});

  @override
  State<LoadRegions> createState() => _LoadRegionsState();
}

class _LoadRegionsState extends State<LoadRegions> {

  final Map<String, List<String>> regionsData = {
  'Ahafo': [
    'Asunafo North Municipal',
    'Asunafo South Municipal',
    'Asutifi North',
    'Asutifi South',
    'Tano North Municipal',
    'Tano South Municipal',
  ],
  'Ashanti': [
    'Adansi Asokwa',
    'Adansi North',
    'Adansi South',
    'Afigya Kwabre North',
    'Afigya Kwabre South',
    'Ahafo Ano North',
    'Ahafo Ano South East',
    'Ahafo Ano South West',
    'Akrofuom',
    'Amansie Central',
    'Amansie South',
    'Amansie West',
    'Asante Akim Central Municipal',
    'Asante Akim North',
    'Asante Akim South Municipal',
    'Atwima Kwanwoma',
    'Atwima Mponua',
    'Atwima Nwabiagya Municipal',
    'Atwima Nwabiagya North',
    'Bekwai Municipal',
    'Bosome Freho',
    'Bosomtwe',
    'Ejisu Municipal',
    'Ejura-Sekyedumase Municipal',
    'Juaben Municipal',
    'Kumasi Metropolitan',
    'Kwabre East',
    'Mampong Municipal',
    'Obuasi East',
    'Obuasi Municipal',
    'Offinso Municipal',
    'Offinso North',
    'Oforikrom Municipal',
    'Old Tafo Municipal',
    'Sekyere Afram Plains',
    'Sekyere Central',
    'Sekyere East',
    'Sekyere Kumawu',
    'Sekyere South',
    'Suame Municipal',
  ],
  'Bono': [
    'Banda',
    'Berekum Municipal',
    'Berekum West',
    'Dormaa Central Municipal',
    'Dormaa East',
    'Dormaa West',
    'Jaman North',
    'Jaman South Municipal',
    'Sunyani Municipal',
    'Sunyani West',
    'Tain',
    'Wenchi Municipal',
  ],
  'Bono East': [
    'Atebubu-Amantin Municipal',
    'Kintampo North Municipal',
    'Kintampo South',
    'Nkoranza North',
    'Nkoranza South Municipal',
    'Pru East',
    'Pru West',
    'Sene East',
    'Sene West',
    'Techiman Municipal',
    'Techiman North',
  ],
  'Central': [
    'Abura-Asebu-Kwamankese',
    'Agona East',
    'Agona West Municipal',
    'Ajumako-Enyan-Essiam',
    'Asikuma-Odoben-Brakwa',
    'Assin North',
    'Assin South',
    'Awutu Senya East Municipal',
    'Awutu Senya West',
    'Cape Coast Metropolitan',
    'Effutu Municipal',
    'Gomoa East',
    'Gomoa West',
    'Komenda/Edina/Eguafo/Abirem Municipal',
    'Mfantseman Municipal',
    'Twifo-Ati-Morkwa',
    'Upper Denkyira East Municipal',
  ],
  'Eastern': [
    'Achiase',
    'Akuapim North',
    'Akuapim South',
    'Akyemansa',
    'Asene Manso Akroso',
    'Asuogyaman',
    'Atiwa East',
    'Atiwa West',
    'Ayensuano',
    'Birim Central Municipal',
    'Birim North',
    'Birim South',
    'Denkyembour',
    'Fanteakwa North',
    'Fanteakwa South',
    'Kwaebibirem Municipal',
    'Kwahu Afram Plains North',
    'Kwahu Afram Plains South',
    'Kwahu East',
    'Kwahu South',
    'Kwahu West Municipal',
    'Lower Manya Krobo Municipal',
    'New Juaben North Municipal',
    'New Juaben South Municipal',
    'Nsawam-Adoagyire Municipal',
    'Okere',
    'Suhum Municipal',
    'Upper Manya Krobo',
    'Upper West Akim',
    'West Akim Municipal',
    'Yilo Krobo Municipal',
  ],
  'Greater Accra': [
    'Ablekuma Central Municipal',
    'Ablekuma North Municipal',
    'Ablekuma West Municipal',
    'Accra Metropolitan',
    'Ada East',
    'Ada West',
    'Adenta Municipal',
    'Ashaiman Municipal',
    'Ayawaso Central Municipal',
    'Ayawaso East Municipal',
    'Ayawaso North Municipal',
    'Ayawaso West Municipal',
    'Ga Central Municipal',
    'Ga East Municipal',
    'Ga North Municipal',
    'Ga South Municipal',
    'Ga West Municipal',
    'Korley Klottey Municipal',
    'Kpone Katamanso Municipal',
    'Krowor Municipal',
    'La Dade-Kotopon Municipal',
    'La Nkwantanang Madina Municipal',
    'Ledzokuku Municipal',
    'Ningo Prampram',
    'Okaikwei North Municipal',
    'Shai Osudoku',
    'Tema Metropolitan',
    'Tema West Municipal',
    'Weija-Gbawe Municipal',
  ],
  'North East': [
    'Bunkpurugu-Nyakpanduri',
    'Chereponi',
    'East Mamprusi Municipal',
    'Mamprugu-Moagduri',
    'West Mamprusi Municipal',
    'Yunyoo-Nasuan',
  ],
  'Northern': [
    'Gushegu Municipal',
    'Karaga',
    'Kpandai',
    'Kumbungu',
    'Mion',
    'Nanton',
    'Nanumba North Municipal',
    'Nanumba South',
    'Saboba',
    'Sagnarigu Municipal',
    'Savelugu Municipal',
    'Tamale Metropolitan',
    'Tatale Sanguli',
    'Tolon',
    'Yendi Municipal',
    'Zabzugu',
  ],
  'Oti': [
    'Biakoye',
    'Jasikan',
    'Kadjebi',
    'Krachi East Municipal',
    'Krachi Nchumuru',
    'Krachi West',
    'Nkwanta North',
    'Nkwanta South',
  ],
  'Savannah': [
    'Bole',
    'Central Gonja',
    'East Gonja Municipal',
    'North Gonja',
    'North East Gonja',
    'Sawla-Tuna-Kalba',
    'West Gonja',
  ],
  'Upper East': [
    'Bawku Municipal',
    'Bawku West',
    'Binduri',
    'Bolgatanga East',
    'Bolgatanga Municipal',
    'Bongo',
    'Builsa North Municipal',
    'Builsa South',
    'Garu',
    'Kassena Nankana Municipal',
    'Kassena Nankana West',
    'Nabdam',
    'Pusiga',
    'Talensi',
    'Tempane',
  ],
  'Upper West': [
    'Daffiama Bussie Issa',
    'Jirapa',
    'Lambussie',
    'Lawra',
    'Nadowli-Kaleo',
    'Nandom Municipal',
    'Sissala East Municipal',
    'Sissala West',
    'Wa East',
    'Wa Municipal',
    'Wa West',
  ],
  'Volta': [
    'Adaklu',
    'Afadzato South',
    'Agotime Ziope',
    'Akatsi North',
    'Akatsi South',
    'Anloga',
    'Central Tongu',
    'Ho Municipal',
    'Ho West',
    'Hohoe Municipal',
    'Keta Municipal',
    'Ketu North',
    'Ketu South Municipal',
    'Kpando Municipal',
    'North Dayi',
    'North Tongu',
    'South Dayi',
    'South Tongu',
  ],
  'Western': [
    'Ahanta West',
    'Amenfi Central',
    'Amenfi West',
    'Aowin',
    'Bia East',
    'Bia West',
    'Bibiani-Anhwiaso-Bekwai',
    'Effia-Kwesimintsim Municipal',
    'Ellembelle',
    'Jomoro',
    'Mpohor',
    'Prestea-Huni Valley',
    'Sefwi Akontombra',
    'Sekondi-Takoradi Metropolitan',
    'Shama',
    'Tarkwa-Nsuaem Municipal',
    'Wassa Amenfi East Municipal',
  ],
  'Western North': [
    'Aowin',
    'Bia East',
    'Bia West',
    'Bibiani-Anhwiaso-Bekwai',
    'Juaboso',
    'Sefwi Akontombra',
    'Sefwi Wiawso',
    'Suaman',
  ],
};

final List<String> services = [
  "Men's haircut",
  "Beard trimming and shaping",
  "Hot towel shave",
  "Kids' haircut",
  "Hair styling ",
  "Hair coloring",
  "Scalp massage and treatment",
  "Face massage",
  "Women's haircut",
  "Hair styling ",
  "Hair treatments",
  "Perms and straightening",
  "Hair extensions",
  "Bridal hair",
  "Scalp treatments",
  "Manicure (basic)",
  "Manicure (acrylic)",
  "Manicure (dip powder)",
  "Pedicure (basic)",
  "Pedicure (gel)",
  "Nail art",
  "Nail repair",
  "Paraffin wax treatment",
  "Hand and foot massage",
  "Cuticle care",
  "Acrylic or gel nail extensions",
  "Bridal makeup",
  "Special event makeup",
  "Airbrush makeup",
  "Natural / everyday makeup",
  "HD makeup for video/film",
  "False lashes",
  "Skin prep before makeup",
  "Touch‑up services",
  "Facial treatments",
  "Acne treatment",
  "Microdermabrasion",
  "Chemical peels",
  "Microneedling",
  "LED light therapy",
  "Dermaplaning",
  "Waxing (eyebrow, lip, chin)",
  "Eyebrow shaping (threading, tinting)",
  "Lash lift and tint",
  "Knotless braids",
  "Natural braids",
  "Pony braids",
  "Goddess braids",
];

Future<void> uploadServicesList() async{
final firestore = FirebaseFirestore.instance;
  try {
    await firestore.collection('categories').doc('serviceList').set({
      'services': services
    });
    print('Services list uploaded successfully.');
  } catch (error) {
    print(error);
  }
}


Future<void> uploadRegionsToFirestore() async {
  final firestore = FirebaseFirestore.instance;
  final batch = firestore.batch(); // optional: use batch for efficiency

  for (final entry in regionsData.entries) {
    final regionName = entry.key;
    final districts = entry.value;

    // Option A: Store as array inside region document
    final regionRef = firestore.collection('regions').doc(regionName);
    batch.set(regionRef, {
      'name': regionName,
      'districts': districts,
    });

    // Option B (if you prefer subcollection, uncomment and adapt):
    // final regionRef = firestore.collection('regions').doc(regionName);
    // batch.set(regionRef, {'name': regionName}); // create region doc
    // for (final district in districts) {
    //   final districtRef = regionRef.collection('districts').doc();
    //   batch.set(districtRef, {'name': district});
    // }
  }

  await batch.commit();
  print('All regions uploaded successfully!');
}

@override
  void initState() {
    uploadServicesList();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Hello'),
      ),
    );
  }
}
import 'package:flutter/material.dart';

class UnitScreen extends StatefulWidget {
  const UnitScreen({super.key});

  @override
  State<UnitScreen> createState() => _UnitScreenState();
}

class _UnitScreenState extends State<UnitScreen> {
  final List<Map<String, int?>> units = [
    {'buy': 45, 'sell': 50},
    {'buy': 90, 'sell': 100},
    {'buy': null, 'sell': null},
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xffF8F6F6),

        // AppBar
        appBar: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xffF8F6F6),
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'تنظیمات واحدها',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          actions: [
            TextButton(
              onPressed: _save,
              child: const Text(
                'ذخیره',
                style: TextStyle(
                  color: Color(0xffEA2A33),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),

        // Body
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Header
                  const Text(
                    'لیست واحدهای شارژ',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'مقادیر خرید و فروش کارت‌های شارژ را برای هر واحد تعیین کنید. قیمت‌ها به افغانی هستند.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 16),

                  // Units
                  ...List.generate(units.length, (index) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xffEA2A33).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.sim_card,
                                  size: 20,
                                  color: Color(0xffEA2A33),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                index < 2 ? 'واحد ${index + 1}' : 'واحد جدید',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.grey),
                                onPressed: () {
                                  setState(() => units.removeAt(index));
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          Row(
                            children: [
                              // Buy
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'مقدار خرید',
                                      style: TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      initialValue: units[index]['buy']?.toString(),
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        suffixText: 'AFN',
                                        contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 14),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      onChanged: (v) {
                                        units[index]['buy'] = int.tryParse(v);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Sell
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'مقدار فروش',
                                      style: TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      initialValue: units[index]['sell']?.toString(),
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        suffixText: 'AFN',
                                        contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 14),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      onChanged: (v) {
                                        units[index]['sell'] = int.tryParse(v);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),

                  // Add Unit Button
                  InkWell(
                    onTap: () {
                      setState(() {
                        units.add({'buy': null, 'sell': null});
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.add_circle_outline),
                          SizedBox(width: 8),
                          Text(
                            'افزودن واحد جدید',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 90),
                ],
              ),
            ),

            // Bottom Save Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xffE5E7EB))),
              ),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffEA2A33),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('ذخیره تغییرات'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    debugPrint(units.toString());
  }
}

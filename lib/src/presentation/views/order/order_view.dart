// lib/src/presentation/views/order/order_view.dart

import 'package:flutter/material.dart';
import 'package:monami/src/models/product_model.dart';
import 'package:monami/src/data/remote/orders_service.dart';

class OrderTrackingView extends StatefulWidget {
  final Orders order;
  const OrderTrackingView({super.key, required this.order});

  @override
  State<OrderTrackingView> createState() => _OrderTrackingViewState();
}

class _OrderTrackingViewState extends State<OrderTrackingView> {
  String aiResponse = "Click the button below for a smart delivery update.";
  bool isAiLoading = false;

  final List<String> statusSteps = [
    'pending',
    'processing',
    'shipped',
    'delivered'
  ];

  Future<void> _fetchAiPrediction() async {
    setState(() => isAiLoading = true);
    final result = await OrdersService().getAIShippingEstimate(widget.order);
    setState(() {
      aiResponse = result;
      isAiLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    int currentStep = statusSteps.indexOf(widget.order.status.toLowerCase());
    if (currentStep == -1) currentStep = 0;

    return Scaffold(
      appBar: AppBar(
          title: Text("Track Order #${widget.order.id.substring(0, 6)}")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // AI Assistant Card
            Card(
              elevation: 4,
              color: Colors.deepPurple.shade50,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome, color: Colors.deepPurple),
                        SizedBox(width: 8),
                        Text("Monami AI Assistant",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    isAiLoading
                        ? const CircularProgressIndicator()
                        : Text(aiResponse,
                            style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: isAiLoading ? null : _fetchAiPrediction,
                      icon: const Icon(Icons.psychology),
                      label: const Text("Get AI Prediction"),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Progress Stepper
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: statusSteps.length,
              itemBuilder: (context, index) {
                bool isDone = index <= currentStep;
                return Row(
                  children: [
                    Column(
                      children: [
                        Icon(
                          isDone ? Icons.check_circle : Icons.circle_outlined,
                          color: isDone ? Colors.green : Colors.grey,
                        ),
                        if (index != statusSteps.length - 1)
                          Container(
                              width: 2,
                              height: 40,
                              color:
                                  isDone ? Colors.green : Colors.grey.shade300),
                      ],
                    ),
                    const SizedBox(width: 15),
                    Text(
                      statusSteps[index].toUpperCase(),
                      style: TextStyle(
                        fontWeight:
                            isDone ? FontWeight.bold : FontWeight.normal,
                        color: isDone ? Colors.black : Colors.grey,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

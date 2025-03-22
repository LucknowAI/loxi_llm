import 'package:flutter/material.dart';
import 'dart:async';

import 'package:loki_llm/model/model.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Model List',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ModelListPage(title: 'Available Models'),
    );
  }
}

class ModelListPage extends StatefulWidget {
  const ModelListPage({super.key, required this.title});

  final String title;

  @override
  State<ModelListPage> createState() => _ModelListPageState();
}

class _ModelListPageState extends State<ModelListPage> {
  final List<Model> models = [
    Model(name: 'Model A', size: '50MB', status: 'Downloaded'),
    Model(name: 'Model B', size: '75MB', status: 'Not Downloaded'),
    Model(name: 'Model C', size: '100MB', status: 'Not Downloaded'),
    Model(name: 'Model D', size: '120MB', status: 'Not Downloaded'), // New model
  ];

  void _downloadModel(Model model) {
    setState(() {
      model.status = 'Downloading';
    });

    // Simulate a download process
    Timer(Duration(seconds: 5), () {
      setState(() {
        model.status = 'Downloaded';
      });
    });
  }

  void _pauseDownload(Model model) {
    setState(() {
      model.status = 'Paused';
    });
  }

  void _cancelDownload(Model model) {
    setState(() {
      model.status = 'Not Downloaded';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: ListView.builder(
        itemCount: models.length,
        itemBuilder: (context, index) {
          final model = models[index];
          return ListTile(
            title: Text(model.name),
            subtitle: Text('Size: ${model.size} - Status: ${model.status}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (model.status == 'Downloading')
                  ElevatedButton(
                    onPressed: () => _pauseDownload(model),
                    child: Text('Pause'),
                  ),
                if (model.status == 'Paused')
                  ElevatedButton(
                    onPressed: () => _downloadModel(model),
                    child: Text('Resume'),
                  ),
                if (model.status == 'Downloading' || model.status == 'Paused')
                  ElevatedButton(
                    onPressed: () => _cancelDownload(model),
                    child: Text('Cancel'),
                  ),
                if (model.status == 'Not Downloaded')
                  ElevatedButton(
                    onPressed: () => _downloadModel(model),
                    child: Text('Download'),
                  ),
                if (model.status == 'Downloaded')
                  ElevatedButton(
                    onPressed: () {
                      // Handle load for chat action
                    },
                    child: Text('Load for Chat'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}


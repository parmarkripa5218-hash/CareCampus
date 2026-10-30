import 'package:flutter/material.dart';
import '../../models/resource_model.dart';
import '../../services/services.dart';
import '../../utils/theme.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;

class ResourceHub extends StatefulWidget {
  const ResourceHub({super.key});

  @override
  State<ResourceHub> createState() => _ResourceHubState();
}

class _ResourceHubState extends State<ResourceHub> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Resource> _resources = [];
  bool _isLoading = true;

  final List<String> _categories = ['All', 'Guide', 'Video', 'Audio', 'PDF'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _loadResources();
  }

  Future<void> _loadResources() async {
    try {
      final list = await Services.db.getResources();
      setState(() {
        _resources = list;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await launcher.canLaunchUrl(uri)) {
        await launcher.launchUrl(uri, mode: launcher.LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open link: $url'),
          backgroundColor: AppTheme.alertSevere,
        ),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resource Hub'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: AppTheme.mintAccent,
          labelColor: AppTheme.mintAccent,
          unselectedLabelColor: AppTheme.textLow,
          tabs: _categories.map((c) => Tab(text: c)).toList(),
        ),
      ),
      body: Container(
        height: double.infinity,
        decoration: AppTheme.backgroundGradient,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.tealPrimary))
            : TabBarView(
                controller: _tabController,
                children: _categories.map((cat) {
                  final filtered = cat == 'All'
                      ? _resources
                      : _resources.where((r) => r.category.toLowerCase() == cat.toLowerCase()).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.library_books_outlined, size: 64, color: AppTheme.textLow.withValues(alpha: 0.5)),
                          const SizedBox(height: 16),
                          Text(
                            'No resources found for "$cat".',
                            style: const TextStyle(color: AppTheme.textLow),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, i) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final res = filtered[index];
                      IconData catIcon = Icons.article_outlined;
                      Color catColor = AppTheme.tealPrimary;
                      
                      if (res.category == 'Video') {
                        catIcon = Icons.play_circle_fill_rounded;
                        catColor = Colors.redAccent;
                      } else if (res.category == 'Audio') {
                        catIcon = Icons.audiotrack_rounded;
                        catColor = Colors.orangeAccent;
                      } else if (res.category == 'PDF') {
                        catIcon = Icons.picture_as_pdf_rounded;
                        catColor = Colors.teal;
                      }

                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: AppTheme.glassCardDecoration(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: catColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(catIcon, color: catColor, size: 24),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        res.title,
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Uploaded by ${res.uploadedByName}',
                                        style: const TextStyle(color: AppTheme.textLow, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              res.description,
                              style: const TextStyle(color: AppTheme.textMedium, height: 1.4),
                            ),
                            const Divider(height: 24, color: Colors.white10),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    res.category.toUpperCase(),
                                    style: TextStyle(color: catColor, fontSize: 11, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppTheme.mintAccent,
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                                  label: const Text('Open Resource'),
                                  onPressed: () => _launchUrl(res.url),
                                ),
                              ],
                            )
                          ],
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
      ),
    );
  }
}

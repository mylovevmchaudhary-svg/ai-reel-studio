import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/project_model.dart';
import '../../../data/repositories/project_repository.dart';
import 'create_new_project_screen.dart';
import '../../editor/screens/video_timeline_editor_screen.dart';

class MyProjectsScreen extends StatefulWidget {
  const MyProjectsScreen({Key? key}) : super(key: key);

  @override
  State<MyProjectsScreen> createState() => _MyProjectsScreenState();
}

class _MyProjectsScreenState extends State<MyProjectsScreen> {
  final ProjectRepository _repo = ProjectRepository();
  List<ProjectModel> _allProjects = [];
  List<ProjectModel> _filteredProjects = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() => _isLoading = true);
    _allProjects = await _repo.getProjects();
    _applyFilter();
    setState(() => _isLoading = false);
  }

  void _applyFilter() {
    if (_searchQuery.trim().isEmpty) {
      _filteredProjects = List.from(_allProjects);
    } else {
      _filteredProjects = _allProjects.where((p) => p.title.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
  }

  Future<void> _deleteProject(String id) async {
    await _repo.deleteProject(id);
    _loadProjects();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Project removed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('My Projects'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New Project',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateNewProjectScreen()),
              );
              _loadProjects();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search projects by title...',
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                fillColor: AppColors.cardNavy,
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                  _applyFilter();
                });
              },
            ),
          ),

          // Projects List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.accentPurple))
                : _filteredProjects.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.movie_creation_outlined, size: 48, color: Colors.white38),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isEmpty ? 'No projects yet' : 'No projects matching "$_searchQuery"',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredProjects.length,
                        itemBuilder: (context, index) {
                          final p = _filteredProjects[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: AppColors.cardNavy,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.06)),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryNavy,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.accentPurple.withOpacity(0.3)),
                                ),
                                child: const Center(
                                  child: Icon(Icons.video_library_rounded, color: AppColors.accentPurple, size: 22),
                                ),
                              ),
                              title: Text(
                                p.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.06),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(p.aspectRatio, style: const TextStyle(fontSize: 10, color: Colors.white70)),
                                    ),
                                    const SizedBox(width: 8),
                                    Text('${p.targetDurationSeconds}s • ${p.status}', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.5))),
                                  ],
                                ),
                              ),
                              trailing: PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, color: Colors.white54),
                                color: AppColors.cardNavy,
                                onSelected: (val) {
                                  if (val == 'delete') _deleteProject(p.id);
                                },
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete Project', style: TextStyle(color: AppColors.error)),
                                  ),
                                ],
                              ),
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => VideoTimelineEditorScreen(projectId: p.id)),
                                );
                                _loadProjects();
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

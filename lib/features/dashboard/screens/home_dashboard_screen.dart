import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/project_model.dart';
import '../../../data/repositories/project_repository.dart';
import '../../projects/screens/create_new_project_screen.dart';
import '../../editor/screens/video_timeline_editor_screen.dart';
import '../../scenes/screens/scene_manager_screen.dart';
import '../../voiceover/screens/voiceover_studio_screen.dart';
import '../../captions/screens/subtitle_editor_screen.dart';
import '../../projects/screens/my_projects_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({Key? key}) : super(key: key);

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  final ProjectRepository _repo = ProjectRepository();
  List<ProjectModel> _recentProjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    final projects = await _repo.getProjects();
    setState(() {
      _recentProjects = projects;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                gradient: AppColors.purplePinkGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.movie_filter_rounded, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text('AI Reel Studio'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentPurple))
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              color: AppColors.accentPurple,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Hero Creation Card
                    _buildHeroCreationCard(),
                    const SizedBox(height: 20),

                    // 2. Quick Studio Tools Grid
                    const Text(
                      'Creative Workflow',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    _buildWorkflowGrid(),
                    const SizedBox(height: 24),

                    // 3. Recent Projects Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Projects',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const MyProjectsScreen()),
                            );
                          },
                          child: const Text('View All', style: TextStyle(color: AppColors.accentPurple)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // 4. Recent Projects List
                    if (_recentProjects.isEmpty)
                      _buildEmptyProjectsCard()
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _recentProjects.take(4).length,
                        itemBuilder: (context, index) {
                          final p = _recentProjects[index];
                          return _buildProjectItemCard(p);
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeroCreationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.heroCardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: AppColors.purplePinkGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'PRO STUDIO',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const Spacer(),
              const Icon(Icons.bolt, color: AppColors.accentPink, size: 20),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Turn Prompts into Viral Reels',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Multi-lingual stories (Hindi, Gujarati, English), scene breakdowns, voiceovers & 9:16 export.',
            style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.7)),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateNewProjectScreen()),
              );
              _loadDashboardData();
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Create New Reel Project'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentPurple,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkflowGrid() {
    final tools = [
      {
        'title': 'New Project',
        'desc': 'Start fresh story',
        'icon': Icons.add_to_photos_rounded,
        'color': AppColors.accentPurple,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateNewProjectScreen())),
      },
      {
        'title': 'Scene Studio',
        'desc': 'Manage & prompts',
        'icon': Icons.view_carousel_outlined,
        'color': AppColors.accentPink,
        'onTap': () {
          if (_recentProjects.isNotEmpty) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => SceneManagerScreen(projectId: _recentProjects.first.id)));
          } else {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateNewProjectScreen()));
          }
        },
      },
      {
        'title': 'Voiceover',
        'desc': 'Record & Free TTS',
        'icon': Icons.mic_rounded,
        'color': AppColors.accentCyan,
        'onTap': () {
          if (_recentProjects.isNotEmpty) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => VoiceoverStudioScreen(projectId: _recentProjects.first.id)));
          } else {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateNewProjectScreen()));
          }
        },
      },
      {
        'title': 'Subtitles',
        'desc': 'SRT & animated',
        'icon': Icons.subtitles_outlined,
        'color': AppColors.warning,
        'onTap': () {
          if (_recentProjects.isNotEmpty) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => SubtitleEditorScreen(projectId: _recentProjects.first.id)));
          } else {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateNewProjectScreen()));
          }
        },
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tools.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      itemBuilder: (context, index) {
        final t = tools[index];
        return InkWell(
          onTap: t['onTap'] as VoidCallback,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardNavy,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(t['icon'] as IconData, color: t['color'] as Color, size: 24),
                const SizedBox(height: 8),
                Text(
                  t['title'] as String,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                ),
                Text(
                  t['desc'] as String,
                  style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.5)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyProjectsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.cardNavy,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          Icon(Icons.video_library_outlined, size: 40, color: Colors.white.withOpacity(0.3)),
          const SizedBox(height: 12),
          const Text(
            'No Projects Created Yet',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            'Enter a story idea to generate your first complete video reel!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectItemCard(ProjectModel project) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.cardNavy,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primaryNavy,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.accentPurple.withOpacity(0.4)),
          ),
          child: const Center(
            child: Icon(Icons.movie_outlined, color: AppColors.accentPurple, size: 20),
          ),
        ),
        title: Text(
          project.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                project.aspectRatio,
                style: const TextStyle(fontSize: 10, color: Colors.white70),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${project.targetDurationSeconds}s • ${project.status}',
              style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.5)),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white38),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VideoTimelineEditorScreen(projectId: project.id),
            ),
          );
          _loadDashboardData();
        },
      ),
    );
  }
}

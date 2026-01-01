import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../core/design/app_spacing.dart';
import '../core/design/visual_enhancements.dart';

/// About University screen with comprehensive information
class AboutUniversityScreen extends StatefulWidget {
  const AboutUniversityScreen({super.key});

  @override
  State<AboutUniversityScreen> createState() => _AboutUniversityScreenState();
}

class _AboutUniversityScreenState extends State<AboutUniversityScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFFAFAFA),
      body: CustomScrollView(
        slivers: [
          _buildEnhancedHeroSection(isDark, size),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    _buildInfoCardsSection(isDark, size),
                    _buildMissionVisionSection(isDark, size),
                    _buildTimelineSection(isDark, size),
                    _buildFacultySection(isDark, size),
                    _buildAchievementsSection(isDark, size),
                    _buildCampusLifeSection(isDark, size),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedHeroSection(bool isDark, Size size) {
    return SliverAppBar(
      expandedHeight: size.height * 0.6,
      floating: false,
      pinned: true,
      backgroundColor: isDark ? const Color(0xFF000000) : Colors.white,
      foregroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 18,
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: null, // Removed annoying title for cleaner look
        centerTitle: true,
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image - Same as home screen
            Image.asset(
              'lib/images/backgroundiu.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      isDark ? const Color(0xFF1F2937) : const Color(0xFF3B82F6),
                      isDark ? const Color(0xFF161B22) : const Color(0xFF1E40AF),
                    ],
                  ),
                ),
              ),
            ),
            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
            // Content
            Positioned(
              bottom: size.height * 0.12,
              left: size.width * 0.08,
              right: size.width * 0.08,
              child: FadeInUp(
                duration: const Duration(milliseconds: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // University Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.school_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Excellence Since 1998',
                            style: GoogleFonts.roboto(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Main Title with Gradient
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [
                          Colors.white,
                          Colors.blue[300]!,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: Text(
                        'Discover IQRA University',
                        style: GoogleFonts.poppins(
                          fontSize: size.width < AppSpacing.mobileBreakpoint ? 32 : 48,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                          letterSpacing: -0.5,
                          color: Colors.white, // This will be masked by the shader
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Subtitle
                    Text(
                      'Leading educational institution committed to excellence, innovation, and developing future leaders',
                      style: GoogleFonts.roboto(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: size.width < AppSpacing.mobileBreakpoint ? 16 : 20,
                        fontWeight: FontWeight.w400,
                        height: 1.5,
                        letterSpacing: 0.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    // Quick Stats Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildQuickStat('25+', 'Years', Icons.calendar_today),
                        _buildQuickStat('50K+', 'Alumni', Icons.people),
                        _buildQuickStat('15+', 'Programs', Icons.school),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStat(String number, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(
            number,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.roboto(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCardsSection(bool isDark, Size size) {
    final infoCards = [
      {
        'icon': Icons.school_rounded,
        'title': 'Academic Excellence',
        'description': 'Comprehensive programs designed to meet industry standards and global requirements.',
        'color': Colors.blue,
      },
      {
        'icon': Icons.science_rounded,
        'title': 'Research & Innovation',
        'description': 'Cutting-edge research facilities and opportunities for groundbreaking discoveries.',
        'color': Colors.green,
      },
      {
        'icon': Icons.groups_rounded,
        'title': 'Student Life',
        'description': 'Vibrant campus community with diverse activities and student organizations.',
        'color': Colors.orange,
      },
      {
        'icon': Icons.business_center_rounded,
        'title': 'Career Development',
        'description': 'Strong industry connections and comprehensive career support services.',
        'color': Colors.purple,
      },
    ];

    return Container(
      padding: EdgeInsets.all(AppSpacing.getResponsivePadding(size)),
      child: Column(
        children: [
          FadeInUp(
            duration: const Duration(milliseconds: 600),
            child: _buildSectionTitle('Why Choose IQRA University', isDark, size),
          ),
          const SizedBox(height: 32),
          if (size.width < AppSpacing.tabletBreakpoint)
            Column(
              children: infoCards.map((card) => Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: _buildInfoCard(card, isDark, size),
              )).toList(),
            )
          else
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: infoCards.map((card) => SizedBox(
                width: (size.width - AppSpacing.getResponsivePadding(size) * 2 - 16) / 2,
                child: _buildInfoCard(card, isDark, size),
              )).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(Map<String, dynamic> card, bool isDark, Size size) {
    final color = card['color'] as Color;
    
    return FadeInUp(
      duration: const Duration(milliseconds: 800),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1B1F) : const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isDark 
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isDark 
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                card['icon'],
                color: isDark ? color.withValues(alpha: 0.8) : color,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              card['title'],
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              card['description'],
              style: GoogleFonts.roboto(
                fontSize: 14,
                height: 1.6,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionVisionSection(bool isDark, Size size) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.getResponsivePadding(size)),
      child: Column(
        children: [
          FadeInUp(
            duration: const Duration(milliseconds: 800),
            child: _buildSectionTitle('Our Mission & Vision', isDark, size),
          ),
          const SizedBox(height: 24),
          if (size.width < AppSpacing.tabletBreakpoint)
            Column(
              children: [
                _buildMissionCard(isDark, size),
                const SizedBox(height: 16),
                _buildVisionCard(isDark, size),
              ],
            )
          else
            Row(
              children: [
                Expanded(child: _buildMissionCard(isDark, size)),
                const SizedBox(width: 24),
                Expanded(child: _buildVisionCard(isDark, size)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildMissionCard(bool isDark, Size size) {
    return FadeInLeft(
      duration: const Duration(milliseconds: 1000),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1B1F) : const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isDark 
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isDark 
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.flag_rounded,
                    color: Colors.green[600],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Mission',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'To provide quality education that develops competent professionals, promotes research and innovation, and contributes to the socio-economic development of Pakistan and the global community.',
              style: GoogleFonts.roboto(
                fontSize: 14,
                height: 1.6,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisionCard(bool isDark, Size size) {
    return FadeInRight(
      duration: const Duration(milliseconds: 1000),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1B1F) : const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isDark 
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isDark 
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.visibility_rounded,
                    color: Colors.purple[600],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Vision',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'To be a leading university recognized globally for academic excellence, innovative research, and producing graduates who are leaders in their fields and contributors to society.',
              style: GoogleFonts.roboto(
                fontSize: 14,
                height: 1.6,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineSection(bool isDark, Size size) {
    final timelineEvents = [
      {'year': '1998', 'title': 'Foundation', 'description': 'IQRA University was established with a vision to provide quality education.'},
      {'year': '2005', 'title': 'Campus Expansion', 'description': 'Expanded to multiple campuses across major cities.'},
      {'year': '2010', 'title': 'Research Excellence', 'description': 'Established research centers and PhD programs.'},
      {'year': '2015', 'title': 'International Recognition', 'description': 'Achieved international accreditation and partnerships.'},
      {'year': '2020', 'title': 'Digital Innovation', 'description': 'Launched online learning platforms and virtual campus tours.'},
      {'year': '2024', 'title': 'Future Ready', 'description': 'Implementing AI and modern technology in education.'},
    ];

    return Container(
      padding: EdgeInsets.all(AppSpacing.getResponsivePadding(size)),
      child: Column(
        children: [
          FadeInUp(
            duration: const Duration(milliseconds: 1000),
            child: _buildSectionTitle('Our Journey', isDark, size),
          ),
          const SizedBox(height: 32),
          ...timelineEvents.asMap().entries.map((entry) {
            final index = entry.key;
            final event = entry.value;
            return FadeInUp(
              duration: Duration(milliseconds: 1200 + (index * 200)),
              child: _buildTimelineItem(
                event['year']!,
                event['title']!,
                event['description']!,
                isDark,
                size,
                index == timelineEvents.length - 1,
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String year, String title, String description, bool isDark, Size size, bool isLast) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark ? Colors.blue[300] : Colors.blue[600],
                  shape: BoxShape.circle,
                  boxShadow: VisualEnhancements.getElevatedShadow(isDark),
                ),
                child: Center(
                  child: Text(
                    year.substring(2),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 60,
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1B1F) : const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: isDark 
                        ? Colors.black.withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: isDark 
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    year,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.blue[300] : Colors.blue[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      height: 1.5,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFacultySection(bool isDark, Size size) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.getResponsivePadding(size)),
      child: Column(
        children: [
          FadeInUp(
            duration: const Duration(milliseconds: 1800),
            child: _buildSectionTitle('Distinguished Faculty', isDark, size),
          ),
          const SizedBox(height: 24),
          FadeInUp(
            duration: const Duration(milliseconds: 2000),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1B1F) : const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: isDark 
                        ? Colors.black.withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: isDark 
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark 
                          ? Colors.teal[300]!.withValues(alpha: 0.1)
                          : Colors.teal[600]!.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.groups_rounded,
                      size: 48,
                      color: isDark ? Colors.teal[300] : Colors.teal[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'World-Class Educators',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Our faculty comprises distinguished academics, industry experts, and researchers who bring real-world experience and cutting-edge knowledge to the classroom. With advanced degrees from prestigious institutions worldwide, they are committed to nurturing the next generation of leaders.',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      height: 1.6,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _buildFacultyTag('PhD Holders: 85%', isDark),
                      _buildFacultyTag('Industry Experience', isDark),
                      _buildFacultyTag('International Faculty', isDark),
                      _buildFacultyTag('Research Publications', isDark),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFacultyTag(String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.teal[800]?.withValues(alpha: 0.3) : Colors.teal[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: GoogleFonts.roboto(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.teal[300] : Colors.teal[700],
        ),
      ),
    );
  }

  Widget _buildAchievementsSection(bool isDark, Size size) {
    final achievements = [
      {
        'icon': Icons.emoji_events_rounded,
        'title': 'HEC Recognition',
        'description': 'Recognized by Higher Education Commission of Pakistan',
        'color': Colors.amber,
      },
      {
        'icon': Icons.public_rounded,
        'title': 'International Partnerships',
        'description': 'Collaborations with universities worldwide',
        'color': Colors.blue,
      },
      {
        'icon': Icons.science_rounded,
        'title': 'Research Excellence',
        'description': 'Leading research in multiple disciplines',
        'color': Colors.green,
      },
      {
        'icon': Icons.business_rounded,
        'title': 'Industry Connections',
        'description': 'Strong ties with leading corporations',
        'color': Colors.purple,
      },
    ];

    return Container(
      padding: EdgeInsets.all(AppSpacing.getResponsivePadding(size)),
      child: Column(
        children: [
          FadeInUp(
            duration: const Duration(milliseconds: 2200),
            child: _buildSectionTitle('Achievements & Recognition', isDark, size),
          ),
          const SizedBox(height: 32),
          if (size.width < AppSpacing.tabletBreakpoint)
            Column(
              children: achievements.map((achievement) => Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: _buildAchievementCard(achievement, isDark, size),
              )).toList(),
            )
          else
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: achievements.map((achievement) => SizedBox(
                width: (size.width - AppSpacing.getResponsivePadding(size) * 2 - 16) / 2,
                child: _buildAchievementCard(achievement, isDark, size),
              )).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(Map<String, dynamic> achievement, bool isDark, Size size) {
    final color = achievement['color'] as Color;
    
    return FadeInUp(
      duration: const Duration(milliseconds: 2400),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1B1F) : const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDark 
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isDark 
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                achievement['icon'],
                color: isDark ? Colors.teal[300] : Colors.teal[600],
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    achievement['title'],
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    achievement['description'],
                    style: GoogleFonts.roboto(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampusLifeSection(bool isDark, Size size) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.getResponsivePadding(size)),
      child: Column(
        children: [
          FadeInUp(
            duration: const Duration(milliseconds: 2600),
            child: _buildSectionTitle('Campus Life', isDark, size),
          ),
          const SizedBox(height: 24),
          FadeInUp(
            duration: const Duration(milliseconds: 2800),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1B1F) : const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: isDark 
                        ? Colors.black.withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: isDark 
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark 
                          ? Colors.indigo[300]!.withValues(alpha: 0.1)
                          : Colors.indigo[600]!.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.location_city_rounded,
                      size: 48,
                      color: isDark ? Colors.indigo[300] : Colors.indigo[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Vibrant Campus Community',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Experience a dynamic campus life with state-of-the-art facilities, diverse student organizations, cultural events, sports activities, and a supportive community that fosters personal and academic growth.',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      height: 1.6,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to virtual tour
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.explore_rounded),
                    label: const Text('Explore Virtual Tour'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.indigo[600] : Colors.indigo[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark, Size size) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: [
          isDark ? Colors.white : Colors.black87,
          isDark ? Colors.blue[300]! : Colors.blue[600]!,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: size.width < AppSpacing.mobileBreakpoint ? 24 : 28,
          fontWeight: FontWeight.bold,
          color: Colors.white, // This will be masked by the shader
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
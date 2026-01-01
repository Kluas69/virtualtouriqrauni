import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../animation/animation_config.dart';
import '../state/futuristic_ui_state.dart';
import 'enhanced_glassmorphic_container.dart';

/// Testimonial model for social proof
class Testimonial {
  final String name;
  final String program;
  final String year;
  final String review;
  final String fullReview;
  final double rating;
  final String avatarUrl;

  const Testimonial({
    required this.name,
    required this.program,
    required this.year,
    required this.review,
    required this.fullReview,
    required this.rating,
    required this.avatarUrl,
  });
}

/// Social proof section with testimonials and statistics
class SocialProofSection extends StatefulWidget {
  final bool isDark;
  final EdgeInsets? padding;

  const SocialProofSection({
    super.key,
    required this.isDark,
    this.padding,
  });

  @override
  State<SocialProofSection> createState() => _SocialProofSectionState();
}

class _SocialProofSectionState extends State<SocialProofSection>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _statsController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  Timer? _rotationTimer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startTestimonialRotation();
  }

  void _initializeAnimations() {
    _rotationController = AnimationController(
      duration: AnimationConfig.fadeTransition,
      vsync: this,
    );

    _statsController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: AnimationConfig.defaultCurve,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: AnimationConfig.smoothCurve,
    ));

    // Start stats animation
    _statsController.forward();
  }

  void _startTestimonialRotation() {
    context.read<FuturisticUIState>().startTestimonialRotation();
    
    _rotationTimer = Timer.periodic(AnimationConfig.testimonialRotation, (timer) {
      _rotateToNext();
    });
    
    // Initial animation
    _rotationController.forward();
  }

  void _rotateToNext() {
    final testimonials = _getTestimonials();
    
    _rotationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % testimonials.length;
        });
        context.read<FuturisticUIState>().setTestimonialExpanded(false);
        _rotationController.forward();
      }
    });
  }

  void _expandTestimonial() {
    context.read<FuturisticUIState>().setTestimonialExpanded(true);
  }

  @override
  void dispose() {
    _rotationTimer?.cancel();
    context.read<FuturisticUIState>().stopTestimonialRotation();
    _rotationController.dispose();
    _statsController.dispose();
    super.dispose();
  }

  List<Testimonial> _getTestimonials() {
    return [
      const Testimonial(
        name: 'Sarah Ahmed',
        program: 'Computer Science',
        year: '2024',
        review: 'The virtual tour gave me an amazing preview of campus life. The interactive features made me feel like I was actually there!',
        fullReview: 'The virtual tour gave me an amazing preview of campus life. The interactive features made me feel like I was actually there! I was able to explore every corner of the campus, from the state-of-the-art library to the modern laboratories. The 3D experience helped me make my decision to apply here.',
        rating: 4.8,
        avatarUrl: 'https://via.placeholder.com/60',
      ),
      const Testimonial(
        name: 'Muhammad Hassan',
        program: 'Engineering',
        year: '2023',
        review: 'Incredible technology! I could explore the labs and facilities in detail before my visit. Highly recommended for prospective students.',
        fullReview: 'Incredible technology! I could explore the labs and facilities in detail before my visit. The virtual tour showed me exactly what to expect, and when I visited in person, everything matched perfectly. The engineering labs are world-class, and the virtual tour captured every detail beautifully.',
        rating: 5.0,
        avatarUrl: 'https://via.placeholder.com/60',
      ),
      const Testimonial(
        name: 'Fatima Khan',
        program: 'Business Administration',
        year: '2024',
        review: 'The virtual tour helped me understand the campus layout perfectly. The quality and attention to detail is outstanding.',
        fullReview: 'The virtual tour helped me understand the campus layout perfectly. As an international student, this was invaluable for planning my studies. The business school facilities are impressive, and the virtual tour made me confident in my choice.',
        rating: 4.9,
        avatarUrl: 'https://via.placeholder.com/60',
      ),
      const Testimonial(
        name: 'Ali Raza',
        program: 'Medicine',
        year: '2023',
        review: 'Outstanding virtual experience! The medical facilities tour convinced me this was the right university for my studies.',
        fullReview: 'Outstanding virtual experience! The medical facilities tour convinced me this was the right university for my studies. The anatomy labs, simulation centers, and hospital facilities are all top-notch. The virtual tour saved me time and helped me prepare for my interview.',
        rating: 4.7,
        avatarUrl: 'https://via.placeholder.com/60',
      ),
      const Testimonial(
        name: 'Aisha Malik',
        program: 'Arts & Design',
        year: '2024',
        review: 'Beautiful presentation of the campus! The art studios and creative spaces look amazing. Can\'t wait to start my studies here.',
        fullReview: 'Beautiful presentation of the campus! The art studios and creative spaces look amazing. The virtual tour showcased the creative environment perfectly, from the design labs to the exhibition spaces. The attention to lighting and atmosphere in the virtual tour really impressed me.',
        rating: 4.6,
        avatarUrl: 'https://via.placeholder.com/60',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final testimonials = _getTestimonials();
    final currentTestimonial = testimonials[_currentIndex];

    return Consumer<FuturisticUIState>(
      builder: (context, state, child) {
        return Container(
          padding: widget.padding ?? const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section title
              Text(
                'What Students Say',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: widget.isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Real experiences from our virtual tour visitors',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: widget.isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 32),
              
              // Statistics and testimonial row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Statistics column
                  Expanded(
                    flex: 1,
                    child: _buildStatsDisplay(),
                  ),
                  
                  const SizedBox(width: 32),
                  
                  // Testimonial column
                  Expanded(
                    flex: 2,
                    child: AnimatedBuilder(
                      animation: _rotationController,
                      builder: (context, child) {
                        return SlideTransition(
                          position: _slideAnimation,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: TestimonialCard(
                              testimonial: currentTestimonial,
                              isDark: widget.isDark,
                              isActive: true,
                              isExpanded: state.isTestimonialExpanded,
                              onTap: _expandTestimonial,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Testimonial indicators
              _buildTestimonialIndicators(testimonials.length),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsDisplay() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tour Statistics',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: widget.isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 20),
        
        _buildStatItem(
          icon: Icons.visibility_rounded,
          label: 'Total Visitors',
          value: '25,847',
          color: Colors.blue,
        ),
        
        const SizedBox(height: 16),
        
        _buildStatItem(
          icon: Icons.star_rounded,
          label: 'Average Rating',
          value: '4.8/5',
          color: Colors.orange,
        ),
        
        const SizedBox(height: 16),
        
        _buildStatItem(
          icon: Icons.check_circle_rounded,
          label: 'Tours Completed',
          value: '18,392',
          color: Colors.green,
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return AnimatedBuilder(
      animation: _statsController,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.8 + (_statsController.value * 0.2),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: widget.isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTestimonialIndicators(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == _currentIndex;
        return AnimatedContainer(
          duration: AnimationConfig.quickActionHover,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? Theme.of(context).primaryColor
                : (widget.isDark ? Colors.white38 : Colors.black38),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

/// Individual testimonial card
class TestimonialCard extends StatefulWidget {
  final Testimonial testimonial;
  final bool isDark;
  final bool isActive;
  final bool isExpanded;
  final VoidCallback onTap;

  const TestimonialCard({
    super.key,
    required this.testimonial,
    required this.isDark,
    required this.isActive,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  State<TestimonialCard> createState() => _TestimonialCardState();
}

class _TestimonialCardState extends State<TestimonialCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      duration: AnimationConfig.fadeTransition,
      vsync: this,
    );

    _expandAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _expandController,
      curve: AnimationConfig.defaultCurve,
    ));
  }

  @override
  void didUpdateWidget(TestimonialCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: TestimonialGlassmorphicContainer(
        isDark: widget.isDark,
        isActive: widget.isActive,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with avatar and info
              Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                    child: Text(
                      widget.testimonial.name.split(' ').map((n) => n[0]).join(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Name and program
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.testimonial.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: widget.isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          '${widget.testimonial.program} • ${widget.testimonial.year}',
                          style: TextStyle(
                            fontSize: 12,
                            color: widget.isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Rating
                  _buildStarRating(widget.testimonial.rating),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Review text
              AnimatedSize(
                duration: AnimationConfig.fadeTransition,
                child: Text(
                  widget.isExpanded 
                      ? widget.testimonial.fullReview 
                      : widget.testimonial.review,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: widget.isDark ? Colors.white.withOpacity(0.87) : Colors.black87,
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Expand button
              if (!widget.isExpanded)
                Text(
                  'Tap to read more...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStarRating(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        final isFilled = rating >= starValue;
        final isHalfFilled = rating >= starValue - 0.5 && rating < starValue;
        
        return Icon(
          isFilled 
              ? Icons.star_rounded
              : isHalfFilled 
                  ? Icons.star_half_rounded
                  : Icons.star_outline_rounded,
          size: 16,
          color: Colors.orange,
        );
      }),
    );
  }
}
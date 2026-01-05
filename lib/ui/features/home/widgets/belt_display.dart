import 'package:flutter/material.dart';
import 'package:self_dojo_mobile/core/theme/app_colors.dart';
import 'package:self_dojo_mobile/domain/models/martial_arts/belt.dart';
import 'package:self_dojo_mobile/domain/models/martial_arts/martial_art.dart';

/// Widget que exibe a faixa/graduação atual
class BeltDisplay extends StatelessWidget {
  const BeltDisplay({
    super.key,
    required this.martialArt,
    required this.belt,
    required this.degree,
  });

  final MartialArt martialArt;
  final Belt? belt;
  final int degree;

  @override
  Widget build(BuildContext context) {
    if (belt == null) {
      return const SizedBox.shrink();
    }

    final beltColor = belt!.color;
    final hasSecondaryColor = belt!.secondaryColor != null;
    final hasDegrees = belt!.hasDegrees && degree > 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            martialArt.primaryColor.withValues(alpha: 0.3),
            martialArt.primaryColor.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: martialArt.primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          // Título
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                martialArt.icon,
                color: martialArt.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Graduação Atual',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondaryDark.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Faixa visual
          Container(
            width: double.infinity,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: beltColor.withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: hasSecondaryColor
                  ? _buildStripedBelt(beltColor, belt!.secondaryColor!)
                  : Container(
                      color: beltColor,
                      child: hasDegrees
                          ? _buildDegreeMarks(beltColor)
                          : null,
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // Nome da faixa
          Text(
            belt!.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryDark,
            ),
          ),

          // Grau (se houver)
          if (hasDegrees) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$degreeº Grau',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStripedBelt(Color primary, Color secondary) {
    return Row(
      children: List.generate(10, (index) {
        return Expanded(
          child: Container(
            color: index.isEven ? primary : secondary,
          ),
        );
      }),
    );
  }

  Widget _buildDegreeMarks(Color beltColor) {
    // Determina a cor das marcas de grau
    final markColor = _getContrastColor(beltColor);

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ...List.generate(degree, (index) {
          return Container(
            width: 8,
            height: 32,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: markColor,
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
        const SizedBox(width: 10),
      ],
    );
  }

  Color _getContrastColor(Color color) {
    // Se a faixa for escura, usa branco; se for clara, usa vermelho/dourado
    final luminance = color.computeLuminance();
    if (luminance > 0.5) {
      return Colors.red.shade700;
    }
    return Colors.white;
  }
}


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
    this.graduation,
  });

  final MartialArt martialArt;
  final Belt? belt;
  final int degree;
  final UserGraduation? graduation;

  @override
  Widget build(BuildContext context) {
    if (belt == null) {
      return const SizedBox.shrink();
    }

    final beltColor = belt!.color;
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
          const SizedBox(height: 20),

          // Faixa visual - estilo realista
          _buildRealisticBelt(beltColor),
          const SizedBox(height: 20),

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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(0),
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

  /// Constrói uma faixa com visual realista
  Widget _buildRealisticBelt(Color beltColor) {
    final hasSecondaryColor = belt!.secondaryColor != null;
    final hasDegrees = belt!.hasDegrees && degree > 0;
    final markColor = belt!.degreeMarkColor ?? Colors.white;

    // Altura proporcional da faixa (como uma faixa real ~4-5cm de altura)
    const double beltHeight = 28;

    return Container(
      width: double.infinity,
      height: beltHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(0),
        child: Stack(
          children: [
            // Corpo da faixa
            Row(
              children: [
                // Parte principal da faixa
                Expanded(
                  child: hasSecondaryColor
                      ? _buildStripedBeltBody(beltColor, belt!.secondaryColor!)
                      : _buildSolidBeltBody(beltColor),
                ),

                // Ponteira (preta ou vermelha para faixa preta)
                if (belt!.hasBlackTip)
                  Builder(
                    builder: (context) {
                      final tipColor = belt!.tipColor ?? Colors.black;
                      final hasRedTip = belt!.tipColor != null; // Faixa preta tem ponteira vermelha
                      const double degreeWidth = 5;
                      const double aparadorWidth = 6.5; // 30% mais largo que graus
                      
                      // Decide se mostra aparadores:
                      // - Se tem graus > 0: sempre mostra
                      // - Se graus = 0: usa o showAparadores da graduação
                      final showAparadores = hasDegrees || (graduation?.showAparadores ?? false);
                      
                      return Container(
                        width: hasRedTip && showAparadores ? 80 : 70,
                        decoration: BoxDecoration(
                          color: tipColor,
                          border: beltColor == tipColor
                              ? Border(
                                  left: BorderSide(
                                    color: tipColor == Colors.black
                                        ? const Color(0xFF333333)
                                        : Colors.black.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                )
                              : null,
                        ),
                        child: Stack(
                          children: [
                            // Textura sutil na ponteira
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.white.withValues(alpha: 0.08),
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.15),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            
                            // Aparadores e graus na ponteira (para faixa preta)
                            if (hasRedTip && showAparadores)
                              Row(
                                children: [
                                  // Aparador esquerdo (colado na borda)
                                  Container(
                                    width: aparadorWidth,
                                    height: beltHeight,
                                    color: markColor,
                                  ),
                                  
                                  // Graus distribuídos uniformemente
                                  Expanded(
                                    child: hasDegrees
                                        ? Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                            children: List.generate(degree, (index) {
                                              return Container(
                                                width: degreeWidth,
                                                height: beltHeight,
                                                color: markColor,
                                              );
                                            }),
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                  
                                  // Aparador direito (colado na borda)
                                  Container(
                                    width: aparadorWidth,
                                    height: beltHeight,
                                    color: markColor,
                                  ),
                                ],
                              )
                            // Apenas graus (para outras faixas com ponteira preta)
                            else if (hasDegrees)
                              Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: List.generate(degree, (index) {
                                    return Container(
                                      width: degreeWidth,
                                      height: beltHeight,
                                      margin: EdgeInsets.only(
                                        left: index == 0 ? 0 : 3,
                                        right: index == degree - 1 ? 6 : 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: markColor,
                                        boxShadow: [
                                          BoxShadow(
                                            color: markColor.withValues(alpha: 0.3),
                                            blurRadius: 2,
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),

                // Pontinha da cor da faixa após a tarja preta
                if (belt!.hasBlackTip)
                  _buildBeltTip(beltColor, beltHeight),
              ],
            ),

            // // Textura de tecido (linha no meio da faixa)
            // if (!hasSecondaryColor)
            //   Positioned(
            //     top: beltHeight / 2 - 0.5,
            //     left: 0,
            //     right: belt!.hasBlackTip ? 60 : 0,
            //     child: Container(
            //       height: 1,
            //       color: Colors.black.withValues(alpha: 0.1),
            //     ),
            //   ),

            // Borda superior sutil (efeito 3D)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Borda inferior sutil (efeito 3D)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Pontinha da cor da faixa após a tarja preta (com corte diagonal)
  Widget _buildBeltTip(Color beltColor, double beltHeight) {
    return ClipPath(
   
      child: Container(
        width: 24,
        height: beltHeight,
        decoration: BoxDecoration(
          color: beltColor,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _lighten(beltColor, 0.1),
              beltColor,
              _darken(beltColor, 0.1),
            ],
          ),
        ),
        child: beltColor == Colors.white
            ? Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 0.5,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  /// Corpo da faixa sólida com textura
  Widget _buildSolidBeltBody(Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _lighten(color, 0.1),
            color,
            _darken(color, 0.1),
          ],
        ),
      ),
      child: color == Colors.white
          ? Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 0.5,
                ),
              ),
            )
          : null,
    );
  }

  /// Corpo da faixa listrada (para faixas kids ou coral)
  Widget _buildStripedBeltBody(Color primary, Color secondary) {
    return Row(
      children: List.generate(5, (index) {
        final color = index.isEven ? primary : secondary;
        return Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: color,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _lighten(color, 0.1),
                  color,
                  _darken(color, 0.1),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Color _lighten(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }

  Color _darken(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }
}



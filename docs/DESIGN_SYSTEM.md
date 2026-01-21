# Design System - Self Dojo Mobile

Este documento descreve o design system do aplicativo Self Dojo Mobile. O design system foi criado para garantir consistência visual e facilitar a manutenção do código.

## 📋 Princípios

1. **Componentização**: Todos os widgets reutilizáveis devem ser componentes do design system
2. **Consistência**: Use sempre os componentes do design system ao invés de criar widgets inline
3. **Manutenibilidade**: Mudanças no design devem ser feitas nos componentes, não nas telas
4. **Documentação**: Novos componentes devem ser documentados aqui

## 🚫 Regras Importantes

### ❌ NÃO FAÇA:
- Criar funções `_buildXxx()` para widgets reutilizáveis
- Usar `Container`, `Text`, `ElevatedButton` diretamente sem componentes do design system
- Duplicar estilos de componentes existentes
- Criar widgets inline com estilos customizados

### ✅ FAÇA:
- Use componentes do design system (`AppButton`, `AppCard`, etc)
- Crie novos componentes se necessário e documente aqui
- Importe componentes de `lib/core/ui/components/components.dart`
- Mantenha consistência visual usando os componentes existentes

## 📦 Componentes Disponíveis

### Botões

#### `AppPrimaryButton`
Botão primário do design system.

```dart
AppPrimaryButton(
  label: 'Salvar',
  onPressed: () {},
  icon: Icons.save, // opcional
  isLoading: false, // opcional
  isFullWidth: false, // opcional
)
```

#### `AppSecondaryButton`
Botão secundário do design system.

```dart
AppSecondaryButton(
  label: 'Cancelar',
  onPressed: () {},
)
```

#### `AppOutlinedButton`
Botão outlined do design system.

```dart
AppOutlinedButton(
  label: 'Mais opções',
  onPressed: () {},
  color: AppColors.secondary, // opcional
)
```

#### `AppTextButton`
Botão de texto do design system.

```dart
AppTextButton(
  label: 'Esqueci minha senha',
  onPressed: () {},
)
```

### Cards

#### `AppStatCard`
Card de estatística usado em dashboards.

```dart
AppStatCard(
  icon: Icons.people,
  label: 'Alunos',
  value: '42',
  maxValue: '/ 50', // opcional
  color: AppColors.primary,
  onTap: () {}, // opcional
)
```

#### `AppInfoCard`
Card de informação com título e conteúdo.

```dart
AppInfoCard(
  title: 'Informações',
  children: [
    AppInfoRow(icon: Icons.person, label: 'Nome', value: 'João'),
    // mais rows...
  ],
)
```

#### `AppMenuItemCard`
Card de item de menu com ícone, título e subtítulo.

```dart
AppMenuItemCard(
  icon: Icons.settings,
  title: 'Configurações',
  subtitle: 'Ajustes do app',
  onTap: () {},
)
```

#### `AppBannerCard`
Card de banner para informações importantes.

```dart
AppBannerCard(
  icon: Icons.card_giftcard,
  title: 'Período de Trial',
  subtitle: '7 dias restantes',
  actionLabel: 'Assinar', // opcional
  onAction: () {}, // opcional
)
```

### Inputs

#### `AppTextField`
Campo de texto do design system.

```dart
AppTextField(
  label: 'Email',
  hint: 'Digite seu email',
  controller: emailController,
  keyboardType: TextInputType.emailAddress,
  validator: (value) => value?.isEmpty ?? true ? 'Campo obrigatório' : null,
  prefixIcon: Icon(Icons.email),
)
```

### Outros Componentes

#### `AppDivider`
Divisor do design system.

```dart
AppDivider(
  height: 32, // opcional
  indent: 20, // opcional
  endIndent: 20, // opcional
)
```

#### `AppIconContainer`
Container de ícone estilizado.

```dart
AppIconContainer(
  icon: Icons.person,
  size: 40,
  color: AppColors.primary, // opcional
  backgroundColor: AppColors.primary.withValues(alpha: 0.15), // opcional
)
```

#### `AppInfoRow`
Linha de informação com ícone, label e valor.

```dart
AppInfoRow(
  icon: Icons.email,
  label: 'Email',
  value: 'usuario@email.com',
)
```

#### `AppLoadingIndicator`
Indicador de carregamento.

```dart
AppLoadingIndicator(
  size: 32, // opcional
  strokeWidth: 3, // opcional
  color: AppColors.primary, // opcional
)
```

#### `AppLoadingScaffold`
Scaffold com indicador de carregamento.

```dart
AppLoadingScaffold(
  message: 'Carregando...', // opcional
)
```

#### `AppSectionTitle`
Título de seção.

```dart
AppSectionTitle(
  title: 'Gerenciamento',
  padding: EdgeInsets.zero, // opcional
)
```

## 🎨 Tema

O design system usa o tema definido em:
- `lib/core/theme/app_colors.dart` - Cores
- `lib/core/theme/app_text_styles.dart` - Estilos de texto
- `lib/core/theme/app_theme.dart` - Tema completo

## 📝 Como Adicionar Novos Componentes

1. Crie o componente em `lib/core/ui/components/`
2. Exporte no arquivo `components.dart`
3. Documente aqui neste arquivo
4. Use o componente nas telas ao invés de criar funções `_buildXxx()`

## 🔄 Migração de Código Antigo

Ao refatorar código existente:

1. Identifique widgets reutilizáveis ou com estilos específicos
2. Substitua por componentes do design system
3. Remova funções `_buildXxx()` que foram substituídas
4. Teste para garantir que a aparência permanece a mesma

## 📚 Exemplos

### Antes (❌):
```dart
Widget _buildStatCard({...}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(...),
    child: Column(...),
  );
}
```

### Depois (✅):
```dart
AppStatCard(
  icon: Icons.people,
  label: 'Alunos',
  value: '42',
  color: AppColors.primary,
)
```

## 🎯 Checklist para Novas Features

Ao criar uma nova tela ou feature:

- [ ] Use componentes do design system
- [ ] Não crie funções `_buildXxx()` para widgets reutilizáveis
- [ ] Use `AppTextField` para inputs
- [ ] Use `AppButton` para botões
- [ ] Use `AppCard` para cards
- [ ] Use `AppSectionTitle` para títulos de seção
- [ ] Use `AppDivider` para divisores
- [ ] Se precisar de um componente novo, crie e documente

## 📞 Suporte

Se você precisar de um componente que não existe:
1. Verifique se já existe algo similar
2. Considere criar um novo componente se for reutilizável
3. Documente o novo componente aqui

---

**Última atualização**: Janeiro 2025

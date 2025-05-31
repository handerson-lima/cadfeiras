import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Para formatar datas
import 'package:csv/csv.dart'; // Para gerar CSV
import 'dart:io' show File, Platform, Directory; // Removido Platform se não usado diretamente aqui
import 'package:flutter/foundation.dart' show kIsWeb; // Para verificar se é web

// Para a web, precisamos de 'dart:html' para downloads
import 'dart:html' as html if (dart.library.io) 'dart:io'; // Usado apenas para web

import '../../Model/feirante.dart';
import '../../Pages/Dashboard/dashboard.dart';
import '../../Pages/cadastro feirantes/Components/feiras_selection.dart';
import '../../Pages/cadastro feirantes/Components/produtos_selection.dart';
import '../../services/feirante_service.dart'; // Importe o seu FeiranteService
import '../dashboard/dashboard_screen.dart'; // Para navegação de volta
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart'; // Para salvar arquivos em mobile
import 'package:permission_handler/permission_handler.dart'; // Para gerenciar permissões em mobile

class RelatoriosScreen extends StatefulWidget {
const RelatoriosScreen({super.key});

@override
State<RelatoriosScreen> createState() => _RelatoriosScreenState();
}

class _RelatoriosScreenState extends State<RelatoriosScreen> {
final FeiranteService _feiranteService = FeiranteService();
List<Feirante> _feirantesFiltrados = [];
bool _isLoading = false;

DateTime? _dataCadastroInicio;
DateTime? _dataCadastroFim;
final Set<String> _feirasFiltro = {};
final Set<String> _produtosFiltro = {};

final TextEditingController _cidadeTextController = TextEditingController();
final TextEditingController _minBancasController = TextEditingController();
final TextEditingController _maxBancasController = TextEditingController();

@override
void initState() {
super.initState();
final agora = DateTime.now();
final formatoBrasileiro = DateFormat("dd/MM/yyyy 'às' HH:mm:ss", 'pt_BR');
print('[RelatoriosScreen] initState chamado em: ${formatoBrasileiro.format(agora)}');
_fetchFeirantes();
}

@override
void dispose() {
_minBancasController.dispose();
_maxBancasController.dispose();
_cidadeTextController.dispose();
super.dispose();
}

Future<void> _fetchFeirantes() async {
if (!mounted) return; // Verificar antes de iniciar
setState(() {
_isLoading = true;
});
try {
final feirantes = await _feiranteService.getAllFeirantes();
if (mounted) {
setState(() {
_feirantesFiltrados = feirantes;
});
}
} catch (e) {
if (mounted) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('Erro ao carregar feirantes: $e')),
);
setState(() {
_feirantesFiltrados = [];
});
}
} finally {
if (mounted) {
setState(() {
_isLoading = false;
});
}
}
}

Future<void> _applyFilters() async {
if (!mounted) return;
setState(() {
_isLoading = true;
});
try {
List<Feirante> allFeirantes = await _feiranteService.getAllFeirantes();

_feirantesFiltrados = allFeirantes.where((feirante) {
bool matches = true;

if (_dataCadastroInicio != null && _dataCadastroFim != null && feirante.dataCadastro != null) {
final feiranteDate = DateTime(feirante.dataCadastro!.year, feirante.dataCadastro!.month, feirante.dataCadastro!.day);
final startDate = DateTime(_dataCadastroInicio!.year, _dataCadastroInicio!.month, _dataCadastroInicio!.day);
final endDate = DateTime(_dataCadastroFim!.year, _dataCadastroFim!.month, _dataCadastroFim!.day).add(const Duration(days: 1, microseconds: -1));
if (feiranteDate.isBefore(startDate) || feiranteDate.isAfter(endDate)) {
matches = false;
}
} else if ((_dataCadastroInicio != null || _dataCadastroFim != null) && feirante.dataCadastro == null) {
matches = false;
}

if (_feirasFiltro.isNotEmpty) {
bool feiraMatch = false;
for (var fFiltro in _feirasFiltro) {
if (feirante.feirasSelecionadas.contains(fFiltro)) {
feiraMatch = true;
break;
}
}
if (!feiraMatch) matches = false;
}

if (_produtosFiltro.isNotEmpty) {
bool produtoMatch = false;
for (var pFiltro in _produtosFiltro) {
if (feirante.produtosSelecionados.contains(pFiltro)) {
produtoMatch = true;
break;
}
}
if (!produtoMatch) matches = false;
}

final String cidadeQuery = _cidadeTextController.text.trim().toLowerCase();
if (cidadeQuery.isNotEmpty) {
if (!feirante.cidade.toLowerCase().contains(cidadeQuery)) {
matches = false;
}
}

final int? minBancas = int.tryParse(_minBancasController.text);
final int? maxBancas = int.tryParse(_maxBancasController.text);

if (minBancas != null && feirante.quantidadeBancas < minBancas) {
matches = false;
}
if (maxBancas != null && feirante.quantidadeBancas > maxBancas) {
matches = false;
}

return matches;
}).toList();
} catch (e) {
if (mounted) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('Erro ao aplicar filtros: $e')),
);
}
setState(() { // setState pode ser chamado aqui se mounted
_feirantesFiltrados = [];
});
} finally {
if (mounted) {
setState(() {
_isLoading = false;
});
}
}
}

Future<void> _clearFilters() async {
setState(() {
_dataCadastroInicio = null;
_dataCadastroFim = null;
_feirasFiltro.clear();
_produtosFiltro.clear();
_cidadeTextController.clear();
_minBancasController.clear();
_maxBancasController.clear();
});
await _applyFilters(); // Recarrega e aplica filtros (agora vazios)
}

Future<void> _pickDateRange() async {
final DateTimeRange? picked = await showDateRangePicker(
context: context,
firstDate: DateTime(2000),
lastDate: DateTime.now().add(const Duration(days: 365)), // Permite selecionar datas futuras também
initialDateRange: _dataCadastroInicio != null && _dataCadastroFim != null
? DateTimeRange(start: _dataCadastroInicio!, end: _dataCadastroFim!)
    : null,
);

if (picked != null) {
setState(() {
_dataCadastroInicio = picked.start;
_dataCadastroFim = picked.end;
});
}
}

Future<void> _selectFeirasFilter() async {
final selectedFeiras = await showDialog<Set<String>>(
context: context,
builder: (context) => FeirasSelectionWidget(
initialSelections: _feirasFiltro,
),
);

if (selectedFeiras != null) {
setState(() {
_feirasFiltro.clear();
_feirasFiltro.addAll(selectedFeiras);
});
}
}

Future<void> _selectProdutosFilter() async {
final selectedProdutos = await showDialog<Set<String>>(
context: context,
builder: (context) => ProdutosSelectionWidget(
initialSelections: _produtosFiltro,
),
);

if (selectedProdutos != null) {
setState(() {
_produtosFiltro.clear();
_produtosFiltro.addAll(selectedProdutos);
});
}
}

Future<void> _generateAndExportCsv(List<Feirante> feirantes, String filenamePrefix) async {
if (feirantes.isEmpty) {
if (mounted) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('Nenhum dado para exportar.')),
);
}
return;
}

List<List<dynamic>> csvData = [];
// Adicionar Data Atualização ao cabeçalho do CSV
csvData.add([
'Nome', 'CPF', 'Telefone', 'Cidade', 'Endereço', 'Complemento',
'Dependentes (Sim/Não)', 'Quantidade Dependentes', 'Feiras', 'Produtos',
'Quantidade Bancas', 'Local Coleta', 'Data Cadastro', 'Data Atualização' // Novo cabeçalho
]);

final formatoBrasileiro = DateFormat("dd/MM/yyyy HH:mm", 'pt_BR');

for (var feirante in feirantes) {
csvData.add([
feirante.nome,
feirante.cpf,
feirante.telefone,
feirante.cidade,
feirante.endereco,
feirante.complemento ?? '',
feirante.dependentesQuantidade != null && feirante.dependentesQuantidade! > 0 ? 'Sim' : 'Não',
feirante.dependentesQuantidade ?? 0,
feirante.feirasSelecionadas.join('; '),
feirante.produtosSelecionados.join('; '),
feirante.quantidadeBancas,
feirante.localColeta,
feirante.dataCadastro != null
? formatoBrasileiro.format(feirante.dataCadastro!)
    : '',
feirante.dataAtualizacao != null // Adicionar data de atualização ao CSV
? formatoBrasileiro.format(feirante.dataAtualizacao!)
    : '',
]);
}

String csvString = const ListToCsvConverter().convert(csvData);
final filename = '$filenamePrefix${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';

if (kIsWeb) {
try {
final blob = html.Blob([csvString], 'text/csv;charset=utf-8;'); // Adicionado charset
final url = html.Url.createObjectUrlFromBlob(blob);
final anchor = html.document.createElement('a') as html.AnchorElement
..href = url
..style.display = 'none'
..download = filename;
html.document.body!.children.add(anchor);
anchor.click();
html.document.body!.children.remove(anchor);
html.Url.revokeObjectUrl(url);

if (mounted) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('Relatório CSV "$filename" gerado para download.')),
);
}
} catch (e) {
if (mounted) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('Erro ao gerar arquivo CSV para download: $e')),
);
}
}
} else {
try {
var status = await Permission.storage.request();
if (!status.isGranted) {
if (mounted) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('Permissão de armazenamento negada.')),
);
}
return;
}

final directory = await getExternalStorageDirectory();
if (directory == null) {
throw Exception("Não foi possível obter o diretório de armazenamento externo.");
}

final path = '${directory.path}/$filename';
final file = File(path);
await file.writeAsString(csvString, encoding: utf8); // Adicionado encoding

if (mounted) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('Relatório CSV salvo em: $path')),
);
}
} catch (e) {
if (mounted) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('Erro ao salvar o arquivo CSV: $e')),
);
}
}
}
}

Future<void> _exportFilteredToCsv() async {
await _generateAndExportCsv(_feirantesFiltrados, 'relatorio_feirantes_filtrado_');
}

Future<void> _exportAllToCsv() async {
if (!mounted) return;
setState(() {
_isLoading = true;
});
try {
final allFeirantes = await _feiranteService.getAllFeirantes();
await _generateAndExportCsv(allFeirantes, 'relatorio_feirantes_todos_');
} catch (e) {
if (mounted) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('Erro ao exportar todos os feirantes: $e')),
);
}
} finally {
if (mounted) {
setState(() {
_isLoading = false;
});
}
}
}

Future<void> _exportToPdf() async {
print('[RelatoriosScreen] Iniciando exportação para PDF');
if (_feirantesFiltrados.isEmpty) {
if (mounted) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('Nenhum dado para exportar.')),
);
}
return;
}

try {
final pdf = pw.Document();
final formatoDataHoraBrasileiro = DateFormat("dd/MM/yyyy 'às' HH:mm", 'pt_BR');
final formatoDataBrasileiro = DateFormat('dd/MM/yyyy', 'pt_BR');
final agoraFormatado = formatoDataHoraBrasileiro.format(DateTime.now());


pdf.addPage(
pw.MultiPage(
pageFormat: PdfPageFormat.a4,
margin: const pw.EdgeInsets.all(32),
build: (pw.Context context) {
return [
pw.Center(
child: pw.Text(
'Relatório de Feirantes - CadFeiras',
style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
),
),
pw.SizedBox(height: 8),
pw.Divider(),
pw.SizedBox(height: 8),
pw.Text(
'Gerado em: $agoraFormatado', // Usando data/hora formatada e dinâmica
style: const pw.TextStyle(fontSize: 10),
),
pw.SizedBox(height: 15),
pw.Text(
'Filtros Aplicados:',
style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
),
pw.SizedBox(height: 6),
pw.Text(
_dataCadastroInicio != null && _dataCadastroFim != null
? 'Período de Cadastro: ${formatoDataBrasileiro.format(_dataCadastroInicio!)} - ${formatoDataBrasileiro.format(_dataCadastroFim!)}'
    : 'Período de Cadastro: Não especificado',
style: const pw.TextStyle(fontSize: 9),
),
pw.Text(
_cidadeTextController.text.isNotEmpty
? 'Cidade: ${_cidadeTextController.text}'
    : 'Cidade: Não especificada',
style: const pw.TextStyle(fontSize: 9),
),
pw.Text(
_feirasFiltro.isNotEmpty
? 'Feiras: ${_feirasFiltro.join(', ')}'
    : 'Feiras: Não especificadas',
style: const pw.TextStyle(fontSize: 9),
),
pw.Text(
_produtosFiltro.isNotEmpty
? 'Produtos: ${_produtosFiltro.join(', ')}'
    : 'Produtos: Não especificados',
style: const pw.TextStyle(fontSize: 9),
),
pw.Text(
_minBancasController.text.isNotEmpty || _maxBancasController.text.isNotEmpty
? 'Quantidade de Bancas: ${_minBancasController.text.isNotEmpty ? 'Mín. ${_minBancasController.text}' : ''}${_minBancasController.text.isNotEmpty && _maxBancasController.text.isNotEmpty ? ' - ' : ''}${_maxBancasController.text.isNotEmpty ? 'Máx. ${_maxBancasController.text}' : ''}'
    : 'Quantidade de Bancas: Não especificada',
style: const pw.TextStyle(fontSize: 9),
),
pw.SizedBox(height: 15),
pw.Text(
'Resumo dos Feirantes:',
style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
),
pw.SizedBox(height: 6),
pw.Text(
'Total de Feirantes Filtrados: ${_feirantesFiltrados.length}',
style: const pw.TextStyle(fontSize: 10),
),
pw.Text(
'Média de Bancas por Feirante: ${(_feirantesFiltrados.map((f) => f.quantidadeBancas).fold(0.0, (prev, element) => prev + element) / (_feirantesFiltrados.isNotEmpty ? _feirantesFiltrados.length : 1.0)).toStringAsFixed(2)}',
style: const pw.TextStyle(fontSize: 10),
),
pw.Text(
'Cidades Distintas: ${_feirantesFiltrados.map((f) => f.cidade).toSet().length}',
style: const pw.TextStyle(fontSize: 10),
),
pw.SizedBox(height: 15),
pw.Text(
'Detalhes dos Feirantes Filtrados:',
style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
),
pw.SizedBox(height: 6),
..._feirantesFiltrados.asMap().entries.map((entry) {
int index = entry.key;
Feirante feirante = entry.value;
return pw.Column(
crossAxisAlignment: pw.CrossAxisAlignment.start,
children: [
if (index > 0) pw.SizedBox(height: 10), // Espaço entre feirantes, exceto antes do primeiro
pw.Text(
'Feirante ${index + 1}:',
style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
),
pw.SizedBox(height: 3),
pw.Table(
border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
columnWidths: {
0: const pw.FlexColumnWidth(2.5), // Nome
1: const pw.FlexColumnWidth(1.5), // CPF
2: const pw.FlexColumnWidth(1.5), // Telefone
3: const pw.FlexColumnWidth(1.5), // Cidade
},
children: [
pw.TableRow(
decoration: const pw.BoxDecoration(color: PdfColors.grey800),
children: [
pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text('Nome', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white))),
pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text('CPF', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white))),
pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text('Telefone', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white))),
pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text('Cidade', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white))),
],
),
pw.TableRow(
children: [
pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text(feirante.nome, style: const pw.TextStyle(fontSize: 7))),
pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text(feirante.cpf, style: const pw.TextStyle(fontSize: 7))),
pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text(feirante.telefone, style: const pw.TextStyle(fontSize: 7))),
pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text(feirante.cidade, style: const pw.TextStyle(fontSize: 7))),
],
),
],
),
pw.SizedBox(height: 3),
pw.Table(
border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
columnWidths: {
0: const pw.FlexColumnWidth(3),   // Endereço
1: const pw.FlexColumnWidth(2),   // Complemento
2: const pw.FlexColumnWidth(1),   // Dependentes
3: const pw.FlexColumnWidth(1),   // Qtd Dependentes
},
children: [
pw.TableRow(
decoration: const pw.BoxDecoration(color: PdfColors.grey800),
children: [
pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text('Endereço', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white))),
pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text('Complemento', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white))),
pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text('Dependentes', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white))),
pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text('Qtd Dep.', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white))),
],
),
pw.TableRow(
children: [
pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text(feirante.endereco, style: const pw.TextStyle(fontSize: 7))),
pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text(feirante.complemento ?? '', style: const pw.TextStyle(fontSize: 7))),
pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text(feirante.dependentesQuantidade != null && feirante.dependentesQuantidade! > 0 ? 'Sim' : 'Não', style: const pw.TextStyle(fontSize: 7))),
pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text(feirante.dependentesQuantidade?.toString() ?? '0', style: const pw.TextStyle(fontSize: 7))),
],
),
],
),
pw.SizedBox(height: 3),
pw.Table(
border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
columnWidths: {
0: const pw.FlexColumnWidth(3.5), // Feiras
1: const pw.FlexColumnWidth(3.5), // Produtos
},
children: [
pw.TableRow(
decoration: const pw.BoxDecoration(color: PdfColors.grey800),
children: [
pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text('Feiras', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white))),
pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text('Produtos', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white))),
],
),
pw.TableRow(
children: [
pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text(feirante.feirasSelecionadas.join('; '), style: const pw.TextStyle(fontSize: 7))),
pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text(feirante.produtosSelecionados.join('; '), style: const pw.TextStyle(fontSize: 7))),
],
),
],
),
pw.SizedBox(height: 3),
pw.Table(
border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
columnWidths: {
0: const pw.FlexColumnWidth(1),   // Qtd Bancas
1: const pw.FlexColumnWidth(2),   // Local Coleta
2: const pw.FlexColumnWidth(2),   // Data Cadastro
3: const pw.FlexColumnWidth(2),   // Data Atualização
},
children: [
pw.TableRow(
decoration: const pw.BoxDecoration(color: PdfColors.grey800),
children: [
pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text('Bancas', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white))),
pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text('Local Coleta', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white))),
pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text('Data Cadastro', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white))),
pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text('Data Atualização', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white))),
],
),
pw.TableRow(
children: [
pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text(feirante.quantidadeBancas.toString(), style: const pw.TextStyle(fontSize: 7))),
pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text(feirante.localColeta ?? '', style: const pw.TextStyle(fontSize: 7))),
pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text(
feirante.dataCadastro != null
? formatoDataHoraBrasileiro.format(feirante.dataCadastro!)
    : '',
style: const pw.TextStyle(fontSize: 7))),
pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text(
feirante.dataAtualizacao != null
? formatoDataHoraBrasileiro.format(feirante.dataAtualizacao!)
    : '',
style: const pw.TextStyle(fontSize: 7))),
],
),
],
),
],
);
}).toList(),
];
},
footer: (pw.Context context) {
return pw.Container(
alignment: pw.Alignment.centerRight,
margin: const pw.EdgeInsets.only(top: 1.0 * PdfPageFormat.cm),
child: pw.Text(
'Página ${context.pageNumber} de ${context.pagesCount}',
style: const pw.TextStyle(color: PdfColors.grey, fontSize: 8),
),
);
},
),
);

final pdfBytes = await pdf.save();

if (kIsWeb) {
try {
final blob = html.Blob([pdfBytes], 'application/pdf');
final url = html.Url.createObjectUrlFromBlob(blob);
final anchor = html.document.createElement('a') as html.AnchorElement
..href = url
..style.display = 'none'
..download = 'relatorio_feirantes_filtrado_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
html.document.body!.children.add(anchor);
anchor.click();
html.document.body!.children.remove(anchor);
html.Url.revokeObjectUrl(url);

if (mounted) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('Relatório PDF gerado para download.')),
);
}
} catch (e) {
if (mounted) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('Erro ao gerar o PDF para download: $e')),
);
}
}
} else { // Mobile
try {
PermissionStatus status;
if (Platform.isAndroid && (await _getAndroidSdkInt() ?? 0) >= 30) { // Android 11+
status = await Permission.manageExternalStorage.request();
} else {
status = await Permission.storage.request();
}

if (!status.isGranted) {
if (mounted) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('Permissão de armazenamento negada.')),
);
}
return;
}

final directory = await getApplicationDocumentsDirectory(); // Usar diretório de documentos do app para maior compatibilidade
final downloadsDir = Platform.isAndroid
? '/storage/emulated/0/Download' // Caminho comum para Downloads no Android
    : directory.path; // Para iOS, usar o diretório de documentos

// Tenta criar o diretório de Downloads se não existir (apenas para Android)
if (Platform.isAndroid) {
final dir = Directory(downloadsDir);
if (!await dir.exists()) {
try {
await dir.create(recursive: true);
} catch (e) {
print("Erro ao criar diretório de Downloads: $e. Salvando em diretório de documentos.");
// Fallback para diretório de documentos do app se falhar
// A lógica para path já usaria directory.path se downloadsDir não for acessível
}
}
}

final filePath = '$downloadsDir/relatorio_feirantes_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
final file = File(filePath);
await file.writeAsBytes(pdfBytes);
print('[RelatoriosScreen] PDF gerado em: ${file.path}');

if (mounted) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text('PDF salvo em: ${file.path}'),
duration: const Duration(seconds: 5),
action: SnackBarAction(
label: 'Abrir',
onPressed: () {
OpenFile.open(file.path);
},
),
),
);
}
// Tenta abrir o arquivo após salvar
final result = await OpenFile.open(file.path);
if (result.type != ResultType.done) {
print('[RelatoriosScreen] Erro ao abrir o PDF: ${result.message}');
if (mounted) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('Não foi possível abrir o PDF automaticamente: ${result.message}')),
);
}
} else {
print('[RelatoriosScreen] PDF aberto com sucesso ou tentativa de abertura enviada.');
}

} catch (e) {
print('[RelatoriosScreen] Erro ao gerar/salvar o PDF: $e');
if (mounted) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('Erro ao gerar ou salvar o PDF: $e')),
);
}
}
}
} catch (e) {
print('[RelatoriosScreen] Erro geral ao exportar para PDF: $e');
if (mounted) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('Erro ao gerar o PDF: $e')),
);
}
}
}
// Helper para obter a versão do SDK do Android
Future<int?> _getAndroidSdkInt() async {
if (Platform.isAndroid) {
// Esta é uma forma simplificada. Para uma solução robusta,
// considere usar um plugin como 'device_info_plus'.
// Por agora, vamos assumir que se for Android, pode precisar de manageExternalStorage.
// Uma verificação mais precisa envolveria platform channels ou plugins.
return 30; // Assume SDK >= 30 para simplificar o exemplo de permissão
}
return null;
}


@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: const Text(
'Relatórios de Feirantes',
style: TextStyle(
fontSize: 24,
fontWeight: FontWeight.bold,
color: Colors.white,
),
),
backgroundColor: Colors.grey,
automaticallyImplyLeading: false, // Remove o botão de voltar padrão
),
body: _isLoading
? const Center(child: CircularProgressIndicator())
    : SingleChildScrollView(
padding: const EdgeInsets.all(16.0),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Text(
'Filtros:',
style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
),
const SizedBox(height: 10),
ListTile(
title: Text(
_dataCadastroInicio == null || _dataCadastroFim == null
? 'Selecionar Período de Cadastro'
    : 'Período: ${DateFormat('dd/MM/yyyy', 'pt_BR').format(_dataCadastroInicio!)} - ${DateFormat('dd/MM/yyyy', 'pt_BR').format(_dataCadastroFim!)}',
),
trailing: const Icon(Icons.calendar_today),
onTap: _pickDateRange,
),
const SizedBox(height: 10),
TextFormField(
controller: _cidadeTextController,
decoration: InputDecoration(
labelText: 'Filtrar por Cidade',
prefixIcon: const Icon(Icons.location_city),
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(12),
),
filled: true,
fillColor: Colors.grey[100],
),
),
const SizedBox(height: 16),
Row(
children: [
Expanded(
child: TextFormField(
controller: _minBancasController,
keyboardType: TextInputType.number,
decoration: InputDecoration(
labelText: 'Bancas (Mín.)',
prefixIcon: const Icon(Icons.table_chart),
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(12),
),
filled: true,
fillColor: Colors.grey[100],
),
),
),
const SizedBox(width: 16),
Expanded(
child: TextFormField(
controller: _maxBancasController,
keyboardType: TextInputType.number,
decoration: InputDecoration(
labelText: 'Bancas (Máx.)',
prefixIcon: const Icon(Icons.table_chart),
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(12),
),
filled: true,
fillColor: Colors.grey[100],
),
),
),
],
),
const SizedBox(height: 16),
GestureDetector(
onTap: _selectFeirasFilter,
child: AbsorbPointer(
child: TextField(
decoration: InputDecoration(
labelText: 'Filtrar por Feiras (${_feirasFiltro.length})',
prefixIcon: const Icon(Icons.event),
suffixIcon: const Icon(Icons.arrow_drop_down),
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(12),
),
filled: true,
fillColor: Colors.grey[100],
),
readOnly: true,
// Controller para exibir o texto das feiras selecionadas
controller: TextEditingController(text: _feirasFiltro.isNotEmpty ? _feirasFiltro.join(', ') : ''),
),
),
),
if (_feirasFiltro.isNotEmpty)
Padding(
padding: const EdgeInsets.only(top: 8.0),
child: Wrap(
spacing: 8.0,
runSpacing: 4.0,
children: _feirasFiltro.map((feira) {
return Chip(
label: Text(feira, style: const TextStyle(color: Colors.white)),
backgroundColor: Colors.blueAccent,
deleteIcon: const Icon(Icons.close, size: 18, color: Colors.white),
onDeleted: () {
setState(() {
_feirasFiltro.remove(feira);
});
},
);
}).toList(),
),
),
const SizedBox(height: 16),
GestureDetector(
onTap: _selectProdutosFilter,
child: AbsorbPointer(
child: TextField(
decoration: InputDecoration(
labelText: 'Filtrar por Produtos (${_produtosFiltro.length})',
prefixIcon: const Icon(Icons.storefront),
suffixIcon: const Icon(Icons.arrow_drop_down),
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(12),
),
filled: true,
fillColor: Colors.grey[100],
),
readOnly: true,
controller: TextEditingController(text: _produtosFiltro.isNotEmpty ? _produtosFiltro.join(', ') : ''),
),
),
),
if (_produtosFiltro.isNotEmpty)
Padding(
padding: const EdgeInsets.only(top: 8.0),
child: Wrap(
spacing: 8.0,
runSpacing: 4.0,
children: _produtosFiltro.map((produto) {
return Chip(
label: Text(produto, style: const TextStyle(color: Colors.white)),
backgroundColor: Colors.green,
deleteIcon: const Icon(Icons.close, size: 18, color: Colors.white),
onDeleted: () {
setState(() {
_produtosFiltro.remove(produto);
});
},
);
}).toList(),
),
),
const SizedBox(height: 20),
Row(
mainAxisAlignment: MainAxisAlignment.spaceEvenly,
children: [
ElevatedButton.icon(
onPressed: _applyFilters,
icon: const Icon(Icons.filter_list),
label: const Text('Aplicar Filtros'),
style: ElevatedButton.styleFrom(
minimumSize: const Size(150, 50),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12),
),
),
),
ElevatedButton.icon(
onPressed: _clearFilters,
icon: const Icon(Icons.clear_all),
label: const Text('Limpar Filtros'),
style: ElevatedButton.styleFrom(
backgroundColor: Colors.orangeAccent,
foregroundColor: Colors.white,
minimumSize: const Size(150, 50),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12),
),
),
),
],
),
const Divider(height: 40, thickness: 1),
const Text(
'Resumo dos Feirantes:',
style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
),
const SizedBox(height: 10),
_feirantesFiltrados.isEmpty
? const Text('Nenhum feirante encontrado com os filtros aplicados.')
    : Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'Total de Feirantes Filtrados: ${_feirantesFiltrados.length}',
style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
),
const SizedBox(height: 8),
Text(
'Média de Bancas por Feirante: ${(_feirantesFiltrados.map((f) => f.quantidadeBancas).fold(0.0, (prev, element) => prev + element) / (_feirantesFiltrados.isNotEmpty ? _feirantesFiltrados.length : 1.0)).toStringAsFixed(2)}',
style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
),
const SizedBox(height: 8),
Text(
'Cidades Distintas: ${_feirantesFiltrados.map((f) => f.cidade).toSet().length}',
style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
),
],
),
const Divider(height: 40, thickness: 1),
const Text(
'Opções de Exportação:',
style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
),
const SizedBox(height: 10),
Row(
mainAxisAlignment: MainAxisAlignment.spaceAround,
children: [
Expanded(
child: ElevatedButton.icon(
onPressed: _exportFilteredToCsv,
icon: const Icon(Icons.insert_drive_file),
label: const Text('CSV Filtrados'), // Texto reduzido
style: ElevatedButton.styleFrom(
padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12), // Ajuste padding
minimumSize: const Size(0, 50),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12),
),
),
),
),
const SizedBox(width: 16),
Expanded(
child: ElevatedButton.icon(
onPressed: _exportAllToCsv,
icon: const Icon(Icons.file_download),
label: const Text('CSV Todos'), // Texto reduzido
style: ElevatedButton.styleFrom(
padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12), // Ajuste padding
minimumSize: const Size(0, 50),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12),
),
),
),
),
],
),
const SizedBox(height: 16),
Center(
child: ElevatedButton.icon(
onPressed: _exportToPdf,
icon: const Icon(Icons.picture_as_pdf),
label: const Text('Exportar PDF Filtrados'),
style: ElevatedButton.styleFrom(
minimumSize: const Size(200, 50),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12),
),
),
),
),
const SizedBox(height: 20),
Center(
child: TextButton(
onPressed: () {
Navigator.pushReplacement(
context,
MaterialPageRoute(builder: (context) => const DashboardScreen()),
);
},
style: TextButton.styleFrom(
minimumSize: const Size(200, 50),
),
child: const Text(
'Voltar para o Dashboard',
style: TextStyle(fontSize: 16, color: Colors.blue),
),
),
),
const SizedBox(height: 20), // Espaço extra no final
],
),
),
);
}
}
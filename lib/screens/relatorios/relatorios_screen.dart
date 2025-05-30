import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Para formatar datas
import 'package:csv/csv.dart'; // Para gerar CSV
import 'dart:io' show File, Platform; // Para verificar a plataforma e manipular arquivos
import 'package:flutter/foundation.dart' show kIsWeb; // Para verificar se é web

// Para a web, precisamos de 'dart:html' para downloads
import 'dart:html' as html if (dart.library.io) 'dart:io'; // Usado apenas para web

import '../../Model/feirante.dart';
import '../../Pages/Dashboard/dashboard.dart';
import '../../Pages/cadastro feirantes/Components/feiras_selection.dart';
import '../../Pages/cadastro feirantes/Components/produtos_selection.dart';
import '../../services/feirante_service.dart'; // Importe o seu FeiranteService
import '../dashboard/dashboard_screen.dart';
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
String? _cidadeFiltroController;
TextEditingController _minBancasController = TextEditingController();
TextEditingController _maxBancasController = TextEditingController();

@override
void initState() {
super.initState();
print('[RelatoriosScreen] initState chamado às 05:13 PM -03, Friday, May 30, 2025');
_fetchFeirantes();
}

@override
void dispose() {
_minBancasController.dispose();
_maxBancasController.dispose();
super.dispose();
}

Future<void> _fetchFeirantes() async {
setState(() {
_isLoading = true;
});
try {
final feirantes = await _feiranteService.getAllFeirantes();
setState(() {
_feirantesFiltrados = feirantes;
});
} catch (e) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('Erro ao carregar feirantes: $e')),
);
setState(() {
_feirantesFiltrados = [];
});
} finally {
setState(() {
_isLoading = false;
});
}
}

Future<void> _applyFilters() async {
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
} else if (_dataCadastroInicio != null && feirante.dataCadastro == null) {
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

if (_cidadeFiltroController != null && _cidadeFiltroController!.isNotEmpty) {
if (!feirante.cidade.toLowerCase().contains(_cidadeFiltroController!.toLowerCase())) {
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
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('Erro ao aplicar filtros: $e')),
);
setState(() {
_feirantesFiltrados = [];
});
} finally {
setState(() {
_isLoading = false;
});
}
}

Future<void> _pickDateRange() async {
final DateTimeRange? picked = await showDateRangePicker(
context: context,
firstDate: DateTime(2000),
lastDate: DateTime.now().add(const Duration(days: 365)),
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
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('Nenhum dado para exportar.')),
);
return;
}

List<List<dynamic>> csvData = [];
csvData.add([
'Nome', 'CPF', 'Telefone', 'Cidade', 'Endereço', 'Complemento',
'Dependentes (Sim/Não)', 'Quantidade Dependentes', 'Feiras', 'Produtos',
'Quantidade Bancas', 'Local Coleta', 'Data Cadastro'
]);

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
? DateFormat('dd/MM/yyyy HH:mm').format(feirante.dataCadastro!)
    : '',
]);
}

String csvString = const ListToCsvConverter().convert(csvData);
final filename = '$filenamePrefix${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';

if (kIsWeb) {
try {
final blob = html.Blob([csvString], 'text/csv');
final url = html.Url.createObjectUrlFromBlob(blob);
final anchor = html.document.createElement('a') as html.AnchorElement
..href = url
..style.display = 'none'
..download = filename;
html.document.body!.children.add(anchor);
anchor.click();
html.document.body!.children.remove(anchor);
html.Url.revokeObjectUrl(url);

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('Relatório CSV "$filename" gerado para download.')),
);
} catch (e) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('Erro ao gerar arquivo CSV para download: $e')),
);
}
} else {
try {
var status = await Permission.storage.request();
if (!status.isGranted) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('Permissão de armazenamento negada.')),
);
return;
}

final directory = await getExternalStorageDirectory();
if (directory == null) {
throw Exception("Não foi possível obter o diretório de armazenamento externo.");
}

final path = '${directory.path}/$filename';
final file = File(path);
await file.writeAsString(csvString);

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('Relatório CSV salvo em: $path')),
);
} catch (e) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('Erro ao salvar o arquivo CSV: $e')),
);
}
}
}

Future<void> _exportFilteredToCsv() async {
await _generateAndExportCsv(_feirantesFiltrados, 'relatorio_feirantes_filtrado_');
}

Future<void> _exportAllToCsv() async {
setState(() {
_isLoading = true;
});
try {
final allFeirantes = await _feiranteService.getAllFeirantes();
await _generateAndExportCsv(allFeirantes, 'relatorio_feirantes_todos_');
} catch (e) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('Erro ao exportar todos os feirantes: $e')),
);
} finally {
setState(() {
_isLoading = false;
});
}
}

Future<void> _exportToPdf() async {
print('[RelatoriosScreen] Iniciando exportação para PDF');
if (_feirantesFiltrados.isEmpty) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('Nenhum dado para exportar.')),
);
return;
}

try {
if (kIsWeb) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('Exportação para PDF não suportada na web. Use CSV para download.')),
);
return;
}

final pdf = pw.Document();

pdf.addPage(
pw.MultiPage(
build: (pw.Context context) {
return [
// Cabeçalho personalizado
pw.Center(
child: pw.Text(
'Relatório de Feirantes - CadFeiras',
style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
),
),
pw.SizedBox(height: 10),
pw.Divider(),
pw.SizedBox(height: 10),
pw.Text(
'Gerado em: 05:13 PM -03, Friday, May 30, 2025',
style: const pw.TextStyle(fontSize: 16),
),
pw.SizedBox(height: 20),
// Filtros Aplicados
pw.Text(
'Filtros Aplicados:',
style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
),
pw.SizedBox(height: 10),
pw.Text(
_dataCadastroInicio != null && _dataCadastroFim != null
? 'Período de Cadastro: ${DateFormat('dd/MM/yyyy').format(_dataCadastroInicio!)} - ${DateFormat('dd/MM/yyyy').format(_dataCadastroFim!)}'
    : 'Período de Cadastro: Não especificado',
style: const pw.TextStyle(fontSize: 14),
),
pw.Text(
_cidadeFiltroController != null && _cidadeFiltroController!.isNotEmpty
? 'Cidade: $_cidadeFiltroController'
    : 'Cidade: Não especificada',
style: const pw.TextStyle(fontSize: 14),
),
pw.Text(
_feirasFiltro.isNotEmpty
? 'Feiras: ${_feirasFiltro.join(', ')}'
    : 'Feiras: Não especificadas',
style: const pw.TextStyle(fontSize: 14),
),
pw.Text(
_produtosFiltro.isNotEmpty
? 'Produtos: ${_produtosFiltro.join(', ')}'
    : 'Produtos: Não especificados',
style: const pw.TextStyle(fontSize: 14),
),
pw.Text(
_minBancasController.text.isNotEmpty || _maxBancasController.text.isNotEmpty
? 'Quantidade de Bancas: ${_minBancasController.text.isNotEmpty ? 'Mín. ${_minBancasController.text}' : 'Não especificado'} - ${_maxBancasController.text.isNotEmpty ? 'Máx. ${_maxBancasController.text}' : 'Não especificado'}'
    : 'Quantidade de Bancas: Não especificada',
style: const pw.TextStyle(fontSize: 14),
),
pw.SizedBox(height: 20),
// Seção de Resumo
pw.Text(
'Resumo dos Feirantes:',
style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
),
pw.SizedBox(height: 10),
pw.Text(
'Total de Feirantes Filtrados: ${_feirantesFiltrados.length}',
style: const pw.TextStyle(fontSize: 16),
),
pw.Text(
'Média de Bancas por Feirante: ${(_feirantesFiltrados.map((f) => f.quantidadeBancas).fold(0, (prev, element) => prev + element) / (_feirantesFiltrados.isNotEmpty ? _feirantesFiltrados.length : 1)).toStringAsFixed(2)}',
style: const pw.TextStyle(fontSize: 16),
),
pw.Text(
'Cidades Distintas: ${_feirantesFiltrados.map((f) => f.cidade).toSet().length}',
style: const pw.TextStyle(fontSize: 16),
),
pw.SizedBox(height: 20),
// Tabela de Feirantes Filtrados
pw.Text(
'Detalhes dos Feirantes Filtrados:',
style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
),
pw.SizedBox(height: 10),
pw.Table.fromTextArray(
headers: [
'Nome', 'CPF', 'Telefone', 'Cidade', 'Endereço', 'Complemento',
'Dependentes', 'Qtd Dependentes', 'Feiras', 'Produtos',
'Qtd Bancas', 'Local Coleta', 'Data Cadastro'
],
data: _feirantesFiltrados.map((feirante) {
return [
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
? DateFormat('dd/MM/yyyy HH:mm').format(feirante.dataCadastro!)
    : '',
];
}).toList(),
border: pw.TableBorder.all(),
cellStyle: const pw.TextStyle(fontSize: 12),
),
];
},
),
);

final directory = await getTemporaryDirectory();
final file = File('${directory.path}/relatorio_feirantes_filtrado_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf');
await file.writeAsBytes(await pdf.save());
print('[RelatoriosScreen] PDF gerado em: ${file.path}');

final result = await OpenFile.open(file.path);
if (result.type != ResultType.done) {
print('[RelatoriosScreen] Erro ao abrir o PDF: ${result.message}');
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('Erro ao abrir o PDF: ${result.message}')),
);
} else {
print('[RelatoriosScreen] PDF aberto com sucesso');
}
} catch (e) {
print('[RelatoriosScreen] Erro ao gerar o PDF: $e');
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text('Erro ao gerar o PDF: $e')),
);
}
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
automaticallyImplyLeading: false,
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
_dataCadastroInicio == null
? 'Selecionar Período de Cadastro'
    : 'Período: ${DateFormat('dd/MM/yyyy').format(_dataCadastroInicio!)} - ${DateFormat('dd/MM/yyyy').format(_dataCadastroFim!)}',
),
trailing: const Icon(Icons.calendar_today),
onTap: _pickDateRange,
),
const SizedBox(height: 10),
TextFormField(
initialValue: _cidadeFiltroController,
decoration: InputDecoration(
labelText: 'Filtrar por Cidade',
prefixIcon: const Icon(Icons.location_city),
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(12),
),
filled: true,
fillColor: Colors.grey[100],
),
onChanged: (value) {
_cidadeFiltroController = value.isEmpty ? null : value;
},
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
labelText: 'Filtrar por Feiras',
prefixIcon: const Icon(Icons.event),
suffixIcon: const Icon(Icons.arrow_drop_down),
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(12),
),
filled: true,
fillColor: Colors.grey[100],
),
readOnly: true,
controller: TextEditingController(
text: _feirasFiltro.isEmpty ? '' : _feirasFiltro.join(', '),
),
),
),
),
if (_feirasFiltro.isNotEmpty)
Padding(
padding: const EdgeInsets.only(top: 8.0),
child: Wrap(
spacing: 8.0,
runSpacing: 8.0,
children: _feirasFiltro.map((feira) {
return Chip(
label: Text(feira, style: const TextStyle(color: Colors.white)),
backgroundColor: Colors.blue,
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
labelText: 'Filtrar por Produtos',
prefixIcon: const Icon(Icons.storefront),
suffixIcon: const Icon(Icons.arrow_drop_down),
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(12),
),
filled: true,
fillColor: Colors.grey[100],
),
readOnly: true,
controller: TextEditingController(
text: _produtosFiltro.isEmpty ? '' : _produtosFiltro.join(', '),
),
),
),
),
if (_produtosFiltro.isNotEmpty)
Padding(
padding: const EdgeInsets.only(top: 8.0),
child: Wrap(
spacing: 8.0,
runSpacing: 8.0,
children: _produtosFiltro.map((produto) {
return Chip(
label: Text(produto, style: const TextStyle(color: Colors.white)),
backgroundColor: Colors.blue,
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
Center(
child: ElevatedButton.icon(
onPressed: _applyFilters,
icon: const Icon(Icons.filter_list),
label: const Text('Aplicar Filtros'),
style: ElevatedButton.styleFrom(
minimumSize: const Size(200, 50),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12),
),
),
),
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
'Média de Bancas por Feirante: ${(_feirantesFiltrados.map((f) => f.quantidadeBancas).fold(0, (prev, element) => prev + element) / (_feirantesFiltrados.isNotEmpty ? _feirantesFiltrados.length : 1)).toStringAsFixed(2)}',
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
label: const Text('Exportar Filtrados (CSV)'),
style: ElevatedButton.styleFrom(
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
label: const Text('Exportar Todos (CSV)'),
style: ElevatedButton.styleFrom(
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
label: const Text('Exportar PDF'),
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
],
),
),
);
}
}
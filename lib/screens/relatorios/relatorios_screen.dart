import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Para formatar datas
import 'package:csv/csv.dart'; // Para gerar CSV
import 'dart:io' show File, Platform; // Para verificar a plataforma (não funciona no web, mas útil para diferenciar)
import 'package:flutter/foundation.dart' show kIsWeb; // Para verificar se é web

// Condicionalmente importar pacotes específicos de plataforma
import 'package:path_provider/path_provider.dart' // Para salvar arquivos em mobile
if (dart.library.html) 'package:flutter_web_plugins/flutter_web_plugins.dart' as web_plugins; // Placeholder para web
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart' // Para gerenciar permissões em mobile
if (dart.library.html) 'package:flutter_web_plugins/flutter_web_plugins.dart' as web_plugins; // Placeholder para web
import 'package:permission_handler/permission_handler.dart';


// Para a web, precisamos de 'dart:html' para downloads.
// Usamos um import condicional para evitar erros de compilação em outras plataformas.
import 'dart:html' as html; // Usado apenas para web

import '../../Model/feirante.dart';
import '../../Pages/Dashboard/dashboard.dart'; // Removido se não for usado explicitamente
import '../../Pages/cadastro feirantes/Components/feiras_selection.dart';
import '../../Pages/cadastro feirantes/Components/produtos_selection.dart';
import '../../services/feirante_service.dart';
import '../dashboard/dashboard_screen.dart';

class RelatoriosScreen extends StatefulWidget {
  const RelatoriosScreen({super.key});

  @override
  State<RelatoriosScreen> createState() => _RelatoriosScreenState();
}

class _RelatoriosScreenState extends State<RelatoriosScreen> {
  final FeiranteService _feiranteService = FeiranteService();
  List<Feirante> _feirantesFiltrados = [];
  bool _isLoading = false;

  // Variáveis para os filtros
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

        // Filtro por data de cadastro
        if (_dataCadastroInicio != null && feirante.dataCadastro != null) {
          final feiranteDate = DateTime(feirante.dataCadastro!.year, feirante.dataCadastro!.month, feirante.dataCadastro!.day);
          final startDate = DateTime(_dataCadastroInicio!.year, _dataCadastroInicio!.month, _dataCadastroInicio!.day);
          final endDate = DateTime(_dataCadastroFim!.year, _dataCadastroFim!.month, _dataCadastroFim!.day);

          if (feiranteDate.isBefore(startDate) || feiranteDate.isAfter(endDate)) {
            matches = false;
          }
        } else if (_dataCadastroInicio != null && feirante.dataCadastro == null) {
          matches = false;
        }

        // Filtro por feiras
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

        // Filtro por produtos
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

        // Filtro por cidade (case-insensitive)
        if (_cidadeFiltroController != null && _cidadeFiltroController!.isNotEmpty) {
          if (!feirante.cidade.toLowerCase().contains(_cidadeFiltroController!.toLowerCase())) {
            matches = false;
          }
        }

        // Filtro: Quantidade de Bancas
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

  // Função genérica para gerar CSV a partir de uma lista de feirantes
  // e lidar com o salvamento/download dependendo da plataforma
  Future<void> _generateAndExportCsv(List<Feirante> feirantes, String filenamePrefix) async {
    if (feirantes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum dado para exportar.')),
      );
      return;
    }

    List<List<dynamic>> csvData = [];
    // Cabeçalho
    csvData.add([
      'Nome', 'CPF', 'Telefone', 'Cidade', 'Endereço', 'Complemento',
      'Dependentes (Sim/Não)', 'Quantidade Dependentes', 'Feiras', 'Produtos',
      'Quantidade Bancas', 'Local Coleta', 'Data Cadastro'
    ]);

    // Dados dos feirantes
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
      // Lógica para web
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
      // Lógica para mobile (Android/iOS)
      try {
        // Solicitar permissão de armazenamento
        var status = await Permission.storage.request();
        if (!status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permissão de armazenamento negada.')),
          );
          return;
        }

        final directory = await getExternalStorageDirectory(); // Para Android
        // Para iOS, você pode usar getApplicationDocumentsDirectory()
        // ou pedir ao usuário onde salvar usando file_picker

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

  // Exportar apenas os feirantes filtrados (função já existente, agora usa a genérica)
  Future<void> _exportFilteredToCsv() async {
    await _generateAndExportCsv(_feirantesFiltrados, 'relatorio_feirantes_filtrado_');
  }

  // NOVA FUNÇÃO: Exportar todos os feirantes (sem filtro)
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funcionalidade de exportar para PDF ainda não implementada.')),
    );
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
            // Filtro por Data de Cadastro
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
            // Filtro por Cidade
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
            // Filtro: Quantidade de Bancas
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
            // Filtro por Feiras
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
            // Filtro por Produtos
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
              'Feirantes Encontrados:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _feirantesFiltrados.isEmpty
                ? const Text('Nenhum feirante encontrado com os filtros aplicados.')
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _feirantesFiltrados.length,
              itemBuilder: (context, index) {
                final feirante = _feirantesFiltrados[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    leading: feirante.foto != null && feirante.foto!.isNotEmpty
                        ? CircleAvatar(
                      backgroundImage: MemoryImage(feirante.foto!),
                    )
                        : const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(feirante.nome),
                    subtitle: Text(
                      'CPF: ${feirante.cpf}\n'
                          'Cidade: ${feirante.cidade}\n'
                          'Bancas: ${feirante.quantidadeBancas}\n'
                          'Feiras: ${feirante.feirasSelecionadas.isEmpty ? 'N/A' : feirante.feirasSelecionadas.join(', ')}',
                    ),
                    isThreeLine: true,
                  ),
                );
              },
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
                    onPressed: _exportFilteredToCsv, // Exporta os filtrados
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
                    onPressed: _exportAllToCsv, // Exporta todos
                    icon: const Icon(Icons.file_download), // Ícone diferente para "todos"
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
            const SizedBox(height: 16), // Espaçamento entre os botões de CSV e PDF
            Center(
              child: ElevatedButton.icon(
                onPressed: _exportToPdf, // Implementar futuramente
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
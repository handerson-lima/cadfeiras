import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'dart:io' show File, Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:path_provider/path_provider.dart'
if (dart.library.html) 'package:flutter_web_plugins/flutter_web_plugins.dart' as web_plugins;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart'
if (dart.library.html) 'package:flutter_web_plugins/flutter_web_plugins.dart' as web_plugins;
import 'package:permission_handler/permission_handler.dart';

import 'dart:html' as html;

import '../../Model/feirante.dart';
import '../../Pages/Dashboard/dashboard.dart';
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
  bool _filtersApplied = false; // NOVA VARIÁVEL DE ESTADO

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
    // No início, não aplicamos filtros, então _filtersApplied é false
    // _feirantesFiltrados pode ficar vazia ou ser preenchida com uma mensagem padrão,
    // já que o resumo só aparecerá se _filtersApplied for true.
    _feirantesFiltrados = []; // Garante que a lista filtrada esteja vazia no início
  }

  @override
  void dispose() {
    _minBancasController.dispose();
    _maxBancasController.dispose();
    super.dispose();
  }

  // Não precisamos de _fetchFeirantes inicial, pois o resumo só aparece com filtro.
  // Se quiser mostrar um resumo "geral" antes de aplicar filtros, o _fetchFeirantes
  // teria que ser ajustado para não setar _filtersApplied como true.

  Future<void> _applyFilters() async {
    setState(() {
      _isLoading = true;
      _filtersApplied = false; // Reseta antes de verificar e aplicar
    });

    try {
      // Verifica se algum filtro foi realmente preenchido
      bool anyFilterActive = _dataCadastroInicio != null ||
          _dataCadastroFim != null ||
          _feirasFiltro.isNotEmpty ||
          _produtosFiltro.isNotEmpty ||
          (_cidadeFiltroController != null && _cidadeFiltroController!.isNotEmpty) ||
          (_minBancasController.text.isNotEmpty && int.tryParse(_minBancasController.text) != null) ||
          (_maxBancasController.text.isNotEmpty && int.tryParse(_maxBancasController.text) != null);


      if (!anyFilterActive) {
        // Se nenhum filtro foi preenchido, apenas exibe mensagem e não mostra o resumo
        setState(() {
          _feirantesFiltrados = [];
          _filtersApplied = false; // Confirma que nenhum filtro foi aplicado
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhum filtro aplicado. Por favor, preencha pelo menos um campo de filtro.')),
        );
        return; // Sai da função se não há filtros
      }

      List<Feirante> allFeirantes = await _feiranteService.getAllFeirantes();

      _feirantesFiltrados = allFeirantes.where((feirante) {
        bool matches = true;

        // Filtro por data de cadastro
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

      setState(() {
        _filtersApplied = true; // Define como true porque filtros foram aplicados
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao aplicar filtros: $e')),
      );
      setState(() {
        _feirantesFiltrados = [];
        _filtersApplied = false; // Em caso de erro, resetar
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

  void _clearFilters() {
    setState(() {
      _dataCadastroInicio = null;
      _dataCadastroFim = null;
      _feirasFiltro.clear();
      _produtosFiltro.clear();
      _cidadeFiltroController = null;
      _minBancasController.clear();
      _maxBancasController.clear();
      _feirantesFiltrados = []; // Limpa os resultados filtrados
      _filtersApplied = false; // Indica que não há filtros aplicados
    });
    // Não chama _fetchFeirantes aqui, pois não queremos exibir o resumo geral
    // Ele simplesmente some até que um novo filtro seja aplicado.
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
    if (!_filtersApplied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum filtro aplicado para exportar dados filtrados.')),
      );
      return;
    }
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
            const SizedBox(height: 10), // Espaço após o botão aplicar filtros
            Center(
              child: ElevatedButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.clear),
                label: const Text('Limpar Filtros'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Colors.orange, // Cor para diferenciar
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const Divider(height: 40, thickness: 1),

            // Condicionalmente exibe o resumo APENAS SE _filtersApplied for true
            if (_filtersApplied) // <-- AQUI ESTÁ A MUDANÇA PRINCIPAL
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Resumo dos Feirantes Filtrados:', // Título mais específico
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
                ],
              ),
            if (!_filtersApplied) // Mensagem quando não há filtros aplicados
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: Center(
                  child: Text(
                    'Preencha os filtros acima e clique em "Aplicar Filtros" para ver o resumo dos feirantes.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.grey),
                  ),
                ),
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
                    onPressed: _exportFilteredToCsv, // Exporta os filtrados (agora condicional)
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
                    onPressed: _exportAllToCsv, // Exporta todos (sempre disponível)
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
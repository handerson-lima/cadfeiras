import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Para formatar datas
import 'package:path_provider/path_provider.dart'; // Para salvar arquivos
import 'package:permission_handler/permission_handler.dart'; // Para gerenciar permissões
import 'dart:io'; // Para operações de arquivo
import 'package:csv/csv.dart'; // Para gerar CSV

import '../../Model/feirante.dart';
import '../../services/feirante_service.dart';
import '../feirante_cadastro/Components/feiras_selection.dart';
import '../feirante_cadastro/Components/produtos_selection.dart';
import '../dashboard/dashboard_screen.dart'; // Para o botão de voltar

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
  String? _cidadeFiltroController; // Use String? para a cidade

  @override
  void initState() {
    super.initState();
    _fetchFeirantes(); // Carrega todos os feirantes inicialmente
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
      // Implemente a lógica de filtragem aqui
      // Por enquanto, vamos simular:
      List<Feirante> allFeirantes = await _feiranteService.getAllFeirantes();

      _feirantesFiltrados = allFeirantes.where((feirante) {
        bool matches = true;

        // Filtro por data de cadastro
        if (_dataCadastroInicio != null && feirante.dataCadastro != null) {
          if (feirante.dataCadastro!.isBefore(_dataCadastroInicio!)) {
            matches = false;
          }
        }
        if (_dataCadastroFim != null && feirante.dataCadastro != null) {
          if (feirante.dataCadastro!.isAfter(_dataCadastroFim!.add(const Duration(days: 1)))) { // Adiciona 1 dia para incluir o dia inteiro
            matches = false;
          }
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

        return matches;
      }).toList();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao aplicar filtros: $e')),
      );
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

  Future<void> _exportToCsv() async {
    if (_feirantesFiltrados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum dado para exportar.')),
      );
      return;
    }

    // Solicitar permissão de armazenamento
    var status = await Permission.storage.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permissão de armazenamento negada.')),
      );
      return;
    }

    // Preparar os dados para CSV
    List<List<dynamic>> csvData = [];
    // Cabeçalho
    csvData.add([
      'Nome', 'CPF', 'Telefone', 'Cidade', 'Endereço', 'Complemento',
      'Dependentes', 'Quantidade Dependentes', 'Feiras', 'Produtos',
      'Quantidade Bancas', 'Local Coleta', 'Data Cadastro'
    ]);

    // Dados dos feirantes
    for (var feirante in _feirantesFiltrados) {
      csvData.add([
        feirante.nome,
        feirante.cpf,
        feirante.telefone,
        feirante.cidade,
        feirante.endereco,
        feirante.complemento ?? '', // Se for null, usa string vazia
        feirante.dependentesQuantidade != null ? 'Sim' : 'Não',
        feirante.dependentesQuantidade ?? '',
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

    try {
      final directory = await getExternalStorageDirectory(); // Para Android
      // Para iOS, você pode usar getApplicationDocumentsDirectory()
      // ou pedir ao usuário onde salvar usando file_picker

      if (directory == null) {
        throw Exception("Não foi possível obter o diretório de armazenamento externo.");
      }

      final path = '${directory.path}/relatorio_feirantes_${DateTime.now().millisecondsSinceEpoch}.csv';
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

  // NOTE: A implementação de exportação para PDF é mais complexa e
  // geralmente requer uma biblioteca como 'pdf' ou 'syncfusion_flutter_pdf'.
  // Por simplicidade, estou deixando o método, mas a implementação completa
  // exigiria um foco maior apenas nele.
  Future<void> _exportToPdf() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funcionalidade de exportar para PDF ainda não implementada.')),
    );
    // Para implementar PDF, você precisaria de:
    // 1. Um pacote como 'pdf' (para gerar o PDF)
    // 2. Lógica para desenhar o conteúdo (tabela, texto) no PDF
    // 3. Salvar o PDF de forma similar ao CSV
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
                    onPressed: _exportToCsv,
                    icon: const Icon(Icons.insert_drive_file),
                    label: const Text('Exportar CSV'),
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
                    onPressed: _exportToPdf, // Implementar futuramente
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Exportar PDF'),
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
            const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: () {
                  // Volta para a DashboardScreen
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
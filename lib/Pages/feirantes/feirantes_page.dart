import 'dart:convert';
import 'package:flutter/material.dart';
import '../../Model/feirante.dart'; // Certifique-se que Feirante.fromJson está correto
import '../../services/feirante_service.dart';
import 'feirante_info.dart';

class FeirantesCadastradosScreen extends StatefulWidget {
  const FeirantesCadastradosScreen({super.key});

  @override
  _FeirantesCadastradosScreenState createState() =>
      _FeirantesCadastradosScreenState();
}

class _FeirantesCadastradosScreenState
    extends State<FeirantesCadastradosScreen> {
  final List<Feirante> _allFeirantesFromService = [];
  List<Feirante> _displayedFeirantes = [];
  final TextEditingController _searchController = TextEditingController();
  final FeiranteService _feiranteService = FeiranteService();

  bool _isLoadingInitial = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  final ScrollController _scrollController = ScrollController();

  int _currentPage = 0;
  final int _limitPerPage = 5;
  bool _hasMoreData = true;

  @override
  void initState() {
    super.initState();
    _fetchFeirantes(isInitialLoad: true);
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 50 && // Buffer reduzido
          !_isLoadingMore &&
          _hasMoreData) {
        print("Scroll listener: Carregando mais feirantes...");
        _fetchFeirantes();
      }
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        // Restaura a lista paginada baseada no que já foi carregado
        _displayedFeirantes.clear();
        int itemsToShow = _currentPage * _limitPerPage;
        if (itemsToShow > _allFeirantesFromService.length) {
          itemsToShow = _allFeirantesFromService.length;
        }
        // Se _currentPage é 0, significa que ainda não carregamos nenhuma "página completa"
        // então mostramos a primeira página potencial.
        if (itemsToShow == 0 && _allFeirantesFromService.isNotEmpty) {
          itemsToShow = _limitPerPage > _allFeirantesFromService.length ? _allFeirantesFromService.length : _limitPerPage;
        }

        _displayedFeirantes.addAll(_allFeirantesFromService.sublist(0, itemsToShow));
        _hasMoreData = _displayedFeirantes.length < _allFeirantesFromService.length;

        // Tenta preencher a tela novamente se necessário
        _checkAndFillScreen();

      } else {
        _displayedFeirantes = _allFeirantesFromService.where((feirante) {
          final nomeLower = feirante.nome.toLowerCase();
          final cpfLower = feirante.cpf.toLowerCase();
          return nomeLower.contains(query) || cpfLower.contains(query);
        }).toList();
        _hasMoreData = false; // Desabilita paginação por scroll durante pesquisa local
      }
    });
  }


  Future<void> _fetchFeirantes({bool isInitialLoad = false}) async {
    if (isInitialLoad) {
      setState(() {
        _isLoadingInitial = true;
        _errorMessage = null;
        _allFeirantesFromService.clear();
        _displayedFeirantes.clear();
        _currentPage = 0;
        _hasMoreData = true;
      });
    } else {
      if (_isLoadingMore || !_hasMoreData) return;
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      // Na simulação, _allFeirantesFromService é preenchido uma vez no isInitialLoad.
      // Se o serviço suportasse paginação, a chamada seria aqui com offset e limit.
      if (isInitialLoad) {
        final records = await _feiranteService.fetchFeirantes(); // Busca TODOS os registros
        print("FeiranteService retornou ${records.length} registros.");
        _allFeirantesFromService.clear();
        _allFeirantesFromService.addAll(records.map((record) {
          return Feirante.fromJson(record); // Adapte conforme sua classe Feirante
        }).toList());
      }

      // Simula pegar a "página" correta de _allFeirantesFromService
      int startIndex = _currentPage * _limitPerPage;
      List<Feirante> newFeirantesPage = [];

      if (startIndex < _allFeirantesFromService.length) {
        int endIndex = startIndex + _limitPerPage;
        if (endIndex > _allFeirantesFromService.length) {
          endIndex = _allFeirantesFromService.length;
        }
        newFeirantesPage = _allFeirantesFromService.sublist(startIndex, endIndex);
      }

      if (isInitialLoad) {
        _displayedFeirantes.clear(); // Limpa para a carga inicial
      }
      _displayedFeirantes.addAll(newFeirantesPage);

      if (newFeirantesPage.isNotEmpty) {
        _currentPage++; // Incrementa a página para a próxima busca
      }

      // Atualiza _hasMoreData: true se o total exibido for menor que o total disponível no serviço
      _hasMoreData = _displayedFeirantes.length < _allFeirantesFromService.length;

      setState(() {
        if (isInitialLoad) _isLoadingInitial = false;
        _isLoadingMore = false;
      });

      // Após a atualização do estado, verifica se precisa preencher a tela
      if ((isInitialLoad || newFeirantesPage.isNotEmpty) && mounted) { // Adicionado newFeirantesPage.isNotEmpty para evitar chamadas se a última carga foi vazia mas _hasMoreData ainda era true
        _checkAndFillScreen();
      }

    } catch (e) {
      print('Erro detalhado em _fetchFeirantes: $e');
      setState(() {
        _errorMessage = 'Erro ao carregar feirantes: $e';
        if (isInitialLoad) _isLoadingInitial = false;
        _isLoadingMore = false;
        _hasMoreData = false;
      });
    }
  }

  void _checkAndFillScreen() {
    if (!_hasMoreData || _isLoadingMore || _searchController.text.isNotEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients && _scrollController.position.maxScrollExtent == 0.0) {
        // Se não há rolagem E ainda há dados para carregar E não estamos já carregando
        print("Tela não preenchida e há mais dados, buscando próxima página...");
        _fetchFeirantes();
      }
    });
  }


  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Feirantes Cadastrados',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.grey,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Pesquisar por nome ou CPF',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(vertical: 15.0),
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoadingInitial
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
            )
                : _displayedFeirantes.isEmpty && _searchController.text.isNotEmpty
                ? const Center(child: Text('Nenhum feirante encontrado com o termo pesquisado.'))
                : _displayedFeirantes.isEmpty && !_hasMoreData
                ? const Center(child: Text('Nenhum feirante cadastrado.'))
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: _displayedFeirantes.length + (_hasMoreData && _isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _displayedFeirantes.length) {
                  // Este é o item do loader
                  return _isLoadingMore
                      ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                      : const SizedBox.shrink(); // Não mostra nada se não estiver carregando mais
                }

                final feirante = _displayedFeirantes[index];
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.grey[300],
                      child: feirante.foto != null
                          ? ClipOval(
                        child: Image.memory(
                          feirante.foto!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                          const Icon(
                            Icons.person,
                            size: 30,
                            color: Colors.grey,
                          ),
                        ),
                      )
                          : const Icon(
                        Icons.person,
                        size: 30,
                        color: Colors.grey,
                      ),
                    ),
                    title: Text(
                      feirante.nome,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('CPF: ${feirante.cpf}'),
                    trailing: const Icon(Icons.arrow_forward_ios, color: Colors.blue),
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FeiranteInfoScreen(feirante: feirante),
                        ),
                      );
                      if (result == true) {
                        _fetchFeirantes(isInitialLoad: true);
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
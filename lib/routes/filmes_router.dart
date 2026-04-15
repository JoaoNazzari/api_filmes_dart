// lib/router.dart
// Definição das rotas CRUD da API

import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'database.dart';
import 'models/filme.dart'; 

Router filmeRouter(DatabaseHelper db) {
  final router = Router();

  // GET /filmes — Listar todos, filtrar por idade, filtrar por genero ou filtrar por idade e genero
  // Uso: 
      //filmes 
      //filmes?idade=14
      //filmes?genero=Acao
      //filmes?idade=14&genero=Acao
  router.get('/filmes', (Request request) {
    final params = request.requestedUri.queryParameters;
    final idadeStr = params['idade'];
    final genero = params['genero'];

    List<Filme> filmes;

    // Caso 1: Filtro Duplo (Idade E Gênero)
    if (idadeStr != null && genero != null) {
      filmes = db.getByAgeAndGenre(int.parse(idadeStr), genero);
    } 
    // Caso 2: Apenas Idade
    else if (idadeStr != null) {
      filmes = db.getAllowedByAge(int.parse(idadeStr));
    } 
    // Caso 3: Apenas Gênero
    else if (genero != null) {
      filmes = db.getByGenre(genero);
    } 
    // Caso 4: Nenhum filtro (Todos)
    else {
      filmes = db.getAll();
    }

    return Response.ok(
      jsonEncode(filmes.map((f) => f.toJson()).toList()),
      headers: {'Content-Type': 'application/json'},
    );
  });

  // GET /filmes — Buscar por id 
  router.get('/filmes/<id>', (Request request, String id) async {
    final filmeId = int.tryParse(id);

    if (filmeId == null) {
      return Response(400, 
        body: jsonEncode({'erro': 'O ID precisa ser um número válido.'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final filme = db.getById(filmeId);

    if (filme == null) {
      return Response(404, 
        body: jsonEncode({'erro': 'Filme com ID $filmeId não encontrado.'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    return Response.ok(
      jsonEncode(filme.toJson()),
      headers: {'Content-Type': 'application/json'},
    );
  });

  // POST /filmes — Criar novo filme
  router.post('/filmes', (Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>; 

      if (data['titulo'] == null || data['faixaEtaria'] == null) {
        return Response(400,
          body: jsonEncode({'erro': 'Campos "titulo" e "faixaEtaria" são obrigatórios'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final novoFilme = Filme( 
        titulo: data['titulo'] as String,
        genero: data['genero'] as String,
        duracao: data['duracao'] as String,
        faixaEtaria: data['faixaEtaria'] as int, 
      );

      final criada = db.insert(novoFilme);

      return Response(201,
        body: jsonEncode(criada.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response(400,
        body: jsonEncode({'erro': 'Erro ao processar requisição: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  });

  // PUT /filmes/<id> — Atualizar filme
  router.put('/filmes/<id>', (Request request, String id) async {
    final filmeId = int.tryParse(id);
    if (filmeId == null) return Response(400, body: 'ID inválido');

    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final filmeEditado = Filme(
        id: filmeId,
        titulo: data['titulo'] as String,
        genero: data['genero'] as String,
        duracao: data['duracao'] as String,
        faixaEtaria: data['faixaEtaria'] as int,
      );

      final resultado = db.update(filmeId, filmeEditado);
      if (resultado == null) return Response.notFound('Filme não encontrado');

      return Response.ok(jsonEncode(resultado.toJson()), headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response(400, body: 'Erro: $e');
    }
  });

  // DELETE /filmes/<id>
  router.delete('/filmes/<id>', (Request request, String id) {
    final filmeId = int.tryParse(id);
    if (filmeId == null) return Response(400, body: 'ID inválido');

    final deletou = db.delete(filmeId);
    if (!deletou) return Response.notFound('Filme não encontrado');

    return Response.ok(jsonEncode({'mensagem': 'Filme deletado com sucesso'}));
  });

  return router;
}
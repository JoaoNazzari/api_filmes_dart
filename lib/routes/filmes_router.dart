// lib/filmes_router.dart
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'database.dart';
import 'models/filme.dart';

Router filmeRouter(DatabaseHelper db) {
  final router = Router();

  // GET /filmes — Listar todos, filtrar por idade, gênero ou ambos
  router.get('/filmes', (Request request) async {
    final params = request.requestedUri.queryParameters;
    final idadeStr = params['idade'];
    final genero = params['genero'];

    List<Filme> filmes;

    if (idadeStr != null && genero != null) {
      filmes = await db.getByAgeAndGenre(int.parse(idadeStr), genero);
    } else if (idadeStr != null) {
      filmes = await db.getAllowedByAge(int.parse(idadeStr));
    } else if (genero != null) {
      filmes = await db.getByGenre(genero);
    } else {
      filmes = await db.getAll();
    }

    return Response.ok(
      jsonEncode(filmes.map((f) => f.toJson()).toList()),
      headers: {'Content-Type': 'application/json'},
    );
  });

  // GET /filmes/<id> — Buscar por ID
  router.get('/filmes/<id>', (Request request, String id) async {
    final filmeId = int.tryParse(id);

    if (filmeId == null) {
      return Response(400,
        body: jsonEncode({'erro': 'O ID precisa ser um número válido.'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final filme = await db.getById(filmeId);

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
        id: 0,
        titulo: data['titulo'] as String,
        genero: data['genero'] as String,
        duracao: data['duracao'] as String,
        faixaEtaria: data['faixaEtaria'] as int,
      );

      final criado = await db.insert(novoFilme);

      return Response(201,
        body: jsonEncode(criado.toJson()),
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
    if (filmeId == null) {
      return Response(400,
        body: jsonEncode({'erro': 'ID inválido'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

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

      final resultado = await db.update(filmeId, filmeEditado);
      if (resultado == null) {
        return Response(404,
          body: jsonEncode({'erro': 'Filme não encontrado'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode(resultado.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response(400,
        body: jsonEncode({'erro': 'Erro: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  });

  // DELETE /filmes/<id>
  router.delete('/filmes/<id>', (Request request, String id) async {
    final filmeId = int.tryParse(id);
    if (filmeId == null) {
      return Response(400,
        body: jsonEncode({'erro': 'ID inválido'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final deletou = await db.delete(filmeId);
    if (!deletou) {
      return Response(404,
        body: jsonEncode({'erro': 'Filme não encontrado'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    return Response.ok(
      jsonEncode({'mensagem': 'Filme deletado com sucesso'}),
      headers: {'Content-Type': 'application/json'},
    );
  });

  return router;
}

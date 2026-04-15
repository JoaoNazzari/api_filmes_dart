// lib/database.dart
// Gerenciamento do banco de dados PostgreSQL (Neon)

import 'dart:io';
import 'package:postgres/postgres.dart';
import 'models/filmes.dart';

class FilmesDatabaseHelper {
  late Connection _db;

  Future<void> initialize() async {
    // Lê a connection string do arquivo .env na raiz do projeto
    final envFile = File(Platform.script.resolve('../.env').toFilePath());
    final connectionString = (await envFile.readAsString()).trim();
    final uri = Uri.parse(connectionString);

    _db = await Connection.open(
      Endpoint(
        host: uri.host,
        port: uri.hasPort ? uri.port : 5432,
        database: uri.pathSegments.first,
        username: uri.userInfo.split(':').first,
        password: uri.userInfo.split(':').last,
      ),
      settings: const ConnectionSettings(sslMode: SslMode.require),
    );

    // Cria a tabela se ainda não existir
    await _db.execute('''
      CREATE TABLE IF NOT EXISTS filmes (
        id          SERIAL PRIMARY KEY,
        titulo      TEXT    NOT NULL,
        genero      TEXT    NOT NULL,
        duracao     TEXT    NOT NULL,
        "faixaEtaria" INTEGER NOT NULL DEFAULT 0
      );
    ''');
  }

  // ── helpers internos ──────────────────────────────────────────────────────

  Filme _fromRow(ResultRow row) {
    final m = row.toColumnMap();
    return Filme(
      id: m['id'] as int,
      titulo: m['titulo'] as String,
      genero: m['genero'] as String,
      duracao: m['duracao'] as String,
      faixaEtaria: m['faixaEtaria'] as int,
    );
  }

  // ── queries ───────────────────────────────────────────────────────────────

  /// Retorna todos os filmes
  Future<List<Filme>> getAll() async {
    final result = await _db.execute(
      Sql.named('SELECT * FROM filmes ORDER BY id DESC'),
    );
    return result.map(_fromRow).toList();
  }

  /// Filtra por idade E gênero ao mesmo tempo
  Future<List<Filme>> getByAgeAndGenre(int idade, String genero) async {
    final result = await _db.execute(
      Sql.named(
        'SELECT * FROM filmes WHERE "faixaEtaria" <= @idade AND genero = @genero ORDER BY id DESC',
      ),
      parameters: {'idade': idade, 'genero': genero},
    );
    return result.map(_fromRow).toList();
  }

  /// Retorna filmes permitidos para uma determinada idade
  Future<List<Filme>> getAllowedByAge(int idadeUsuario) async {
    final result = await _db.execute(
      Sql.named(
        'SELECT * FROM filmes WHERE "faixaEtaria" <= @idade ORDER BY "faixaEtaria" DESC',
      ),
      parameters: {'idade': idadeUsuario},
    );
    return result.map(_fromRow).toList();
  }

  /// Retorna filmes filtrados pelo gênero
  Future<List<Filme>> getByGenre(String genero) async {
    final result = await _db.execute(
      Sql.named(
        'SELECT * FROM filmes WHERE genero = @genero ORDER BY id DESC',
      ),
      parameters: {'genero': genero},
    );
    return result.map(_fromRow).toList();
  }

  /// Busca um filme pelo ID
  Future<Filme?> getById(int id) async {
    final result = await _db.execute(
      Sql.named('SELECT * FROM filmes WHERE id = @id'),
      parameters: {'id': id},
    );
    if (result.isEmpty) return null;
    return _fromRow(result.first);
  }

  /// Insere um novo filme e retorna com o ID gerado
  Future<Filme> insert(Filme filme) async {
    final result = await _db.execute(
      Sql.named('''
        INSERT INTO filmes (titulo, genero, duracao, "faixaEtaria")
        VALUES (@titulo, @genero, @duracao, @faixaEtaria)
        RETURNING *
      '''),
      parameters: {
        'titulo': filme.titulo,
        'genero': filme.genero,
        'duracao': filme.duracao,
        'faixaEtaria': filme.faixaEtaria,
      },
    );
    return _fromRow(result.first);
  }

  /// Atualiza um filme existente; retorna null se não encontrado
  Future<Filme?> update(int id, Filme filme) async {
    final result = await _db.execute(
      Sql.named('''
        UPDATE filmes
        SET titulo = @titulo,
            genero = @genero,
            duracao = @duracao,
            "faixaEtaria" = @faixaEtaria
        WHERE id = @id
        RETURNING *
      '''),
      parameters: {
        'id': id,
        'titulo': filme.titulo,
        'genero': filme.genero,
        'duracao': filme.duracao,
        'faixaEtaria': filme.faixaEtaria,
      },
    );
    if (result.isEmpty) return null;
    return _fromRow(result.first);
  }

  /// Deleta um filme pelo ID; retorna true se removeu
  Future<bool> delete(int id) async {
    final result = await _db.execute(
      Sql.named('DELETE FROM filmes WHERE id = @id RETURNING id'),
      parameters: {'id': id},
    );
    return result.isNotEmpty;
  }

  /// Fecha a conexão com o banco
  Future<void> close() async => await _db.close();
}

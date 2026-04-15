// lib/database.dart
// Gerenciamento do banco de dados SQLite

import 'package:postgres/postgres.dart';
import 'models/filme.dart';
import 'models/atores.dart';

class DatabaseHelper {
  late Database _db;

  void initialize() {
    _db = sqlite3.open('filmes.db');
    _db.execute('''
      CREATE TABLE IF NOT EXISTS filmes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        titulo TEXT NOT NULL,
        genero TEXT NOT NULL,
        duracao TEXT NOT NULL,
        faixaEtaria INTEGER NOT NULL DEFAULT 0
      );
    ''');
  }

  /// Retorna todos os filmes
  List<Filme> getAll() {
    final result = _db.select('SELECT * FROM filmes ORDER BY id DESC');
    return result.map((row) => Filme.fromMap(row)).toList();
  }
  
  /// Filtra por idade permitida E gênero ao mesmo tempo
  List<Filme> getByAgeAndGenre(int idade, String genero) {
    final result = _db.select(
      'SELECT * FROM filmes WHERE faixaEtaria <= ? AND genero = ? ORDER BY id DESC',
      [idade, genero],
    );
    return result.map((row) => Filme.fromMap(row)).toList();
  }

  /// Retorna filmes permitidos para uma determinada idade
  List<Filme> getAllowedByAge(int idadeUsuario) {
    final result = _db.select(
      'SELECT * FROM filmes WHERE faixaEtaria <= ? ORDER BY faixaEtaria DESC',
      [idadeUsuario],
    );
    return result.map((row) => Filme.fromMap(row)).toList();
  }

  /// Retorna filmes filtrados pelo genero
 List<Filme> getByGenre(String genero) {
    final result = _db.select(
      'SELECT * FROM filmes WHERE genero = ? ORDER BY id DESC', 
      [genero],
    );
    return result.map((row) => Filme.fromMap(row)).toList();
  }

  /// Busca uma Filme pelo ID
  Filme? getById(int id) {
    final result = _db.select(
      'SELECT * FROM filmes WHERE id = ?',
      [id],
    );
    if (result.isEmpty) return null;
    return Filme.fromMap(result.first);
  }

  /// Insere um novo Filme e retorna ela com o ID gerado
  Filme insert(Filme filme) {
    _db.execute(
      'INSERT INTO filmes (titulo, genero, duracao, faixaEtaria) VALUES (?, ?, ?, ?)',
      [
        filme.titulo, 
        filme.genero, 
        filme.duracao, 
        filme.faixaEtaria
      ],
    );
    final id = _db.lastInsertRowId;
    return getById(id)!;
  }

  /// Atualiza um Filme existente
  Filme? update(int id, Filme filme) {
    final existing = getById(id);
    if (existing == null) return null;

    _db.execute(
      'UPDATE filmes SET titulo = ?, genero = ?, duracao = ?, faixaEtaria = ? WHERE id = ?',
      [
        filme.titulo, 
        filme.genero, 
        filme.duracao, 
        filme.faixaEtaria, 
        id
      ],
    );
    return getById(id);
  }

  /// Deleta um Filme pelo ID. Retorna true se deletou.
  bool delete(int id) {
    final existing = getById(id);
    if (existing == null) return false;

    _db.execute('DELETE FROM filmes WHERE id = ?', [id]);
    return true;
  }

  /// Fecha a conexão com o banco
  void close() {
    _db.close();
  }
}

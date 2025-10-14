import 'dart:io';
import 'dart:math';

// Класс для координат
class Point {
  final int x;
  final int y;
  Point(this.x, this.y);
}

// Класс для корабля
class Ship {
  final String name;
  final int size;
  final List<Point> positions = [];
  bool isSunk = false;

  Ship(this.name, this.size);

  bool checkSunk(List<List<String>> board) {
    isSunk = positions.every((p) => board[p.x][p.y] == 'H');
    return isSunk;
  }
}

// Класс для игровой доски
class Board {
  final int size;
  final List<List<String>> grid;
  final List<Ship> ships = [];

  Board(this.size) : grid = List.generate(size, (_) => List.filled(size, ' '));

  // Проверка, можно ли разместить корабль
  bool canPlaceShip(int startX, int startY, int shipSize, bool isHorizontal) {
    for (int i = 0; i < shipSize; i++) {
      int x = startX + (isHorizontal ? 0 : i);
      int y = startY + (isHorizontal ? i : 0);
      if (x < 0 || x >= size || y < 0 || y >= size) return false;
      // Проверяем клетку и соседей
      for (int dx = -1; dx <= 1; dx++) {
        for (int dy = -1; dy <= 1; dy++) {
          int nx = x + dx;
          int ny = y + dy;
          if (nx >= 0 && nx < size && ny >= 0 && ny < size && grid[nx][ny] == 'S') {
            return false;
          }
        }
      }
    }
    return true;
  }

  // Размещение корабля
  bool placeShip(Ship ship, int startX, int startY, bool isHorizontal) {
    if (!canPlaceShip(startX, startY, ship.size, isHorizontal)) return false;
    for (int i = 0; i < ship.size; i++) {
      int x = startX + (isHorizontal ? 0 : i);
      int y = startY + (isHorizontal ? i : 0);
      grid[x][y] = 'S';
      ship.positions.add(Point(x, y));
    }
    ships.add(ship);
    return true;
  }

  // Атака по клетке
  String attack(int x, int y) {
    if (x < 0 || x >= size || y < 0 || y >= size) return 'I'; // Invalid
    if (grid[x][y] == 'S') {
      grid[x][y] = 'H';
      for (var ship in ships) {
        ship.checkSunk(grid);
      }
      return 'H';
    } else if (grid[x][y] == ' ') {
      grid[x][y] = 'M';
      return 'M';
    }
    return 'A'; // Already attacked
  }

  // Проверка, все ли корабли потоплены
  bool allSunk() {
    return ships.isEmpty || ships.every((ship) => ship.checkSunk(grid));
  }

  // Вывод доски
  void printBoard(bool showShips) {
    stdout.write('   ');
    for (int i = 0; i < size; i++) {
      stdout.write('${(i + 1).toString().padLeft(2)} ');
    }
    stdout.write('\n');
    for (int i = 0; i < size; i++) {
      stdout.write('${(i + 1).toString().padLeft(2)} ');
      for (int j = 0; j < size; j++) {
        String cell = grid[i][j];
        if (!showShips && cell == 'S') cell = ' ';
        stdout.write('${cell.padRight(2)} ');
      }
      stdout.write('\n');
    }
  }
}

void main() {
  print('Добро пожаловать в Морской бой!');
  bool playAgain = true;

  while (playAgain) {
    // Ввод имен
    String player1Name = getPlayerName(1);
    String player2Name = getPlayerName(2);

    // Выбор размера поля
    int size = getBoardSize();
    List<Ship> fleetTemplate = getFleet(size);
    List<Ship> player1Fleet = fleetTemplate.map((s) => Ship(s.name, s.size)).toList();
    List<Ship> player2Fleet = fleetTemplate.map((s) => Ship(s.name, s.size)).toList();

    // Выбор режима
    bool isPvE = getGameMode();
    if (isPvE) player2Name = 'Bot';

    // Создание досок
    Board player1Board = Board(size);
    Board player2Board = Board(size);

    // Размещение кораблей
    print('$player1Name, размещайте корабли:');
    placeShips(player1Board, player1Fleet, false);
    clearConsole();

    if (isPvE) {
      placeShipsBot(player2Board, player2Fleet);
    } else {
      print('$player2Name, размещайте корабли:');
      placeShips(player2Board, player2Fleet, false);
    }
    clearConsole();

    // Случайный первый ход
    bool isPlayer1Turn = Random().nextBool();
    String currentPlayer = isPlayer1Turn ? player1Name : player2Name;

    // Игровой цикл
    bool gameOver = false;
    while (!gameOver) {
      print('Ходит $currentPlayer:');
      Board ownBoard = currentPlayer == player1Name ? player1Board : player2Board;
      Board opponentBoard = currentPlayer == player1Name ? player2Board : player1Board;

      print('Ваше поле:');
      ownBoard.printBoard(true);
      print('Поле соперника:');
      opponentBoard.printBoard(false);

      if (isPvE && currentPlayer == 'Bot') {
        botAttack(opponentBoard);
      } else {
        playerAttack(opponentBoard, currentPlayer);
      }

      // Проверка победы
      if (opponentBoard.allSunk()) {
        clearConsole();
        print('Ходит $currentPlayer:');
        print('Ваше поле:');
        ownBoard.printBoard(true);
        print('Поле соперника:');
        opponentBoard.printBoard(false);
        print('$currentPlayer выиграл!');
        gameOver = true;
      }

      if (!gameOver) {
        currentPlayer = currentPlayer == player1Name ? player2Name : player1Name;
        clearConsole();
      }
    }

    playAgain = askPlayAgain();
  }
  print('Игра завершена. Пока!');
}

// Ввод имени игрока
String getPlayerName(int num) {
  stdout.write('Игрок $num, введите имя: ');
  return stdin.readLineSync()?.trim() ?? 'Player$num';
}

// Выбор размера поля
int getBoardSize() {
  while (true) {
    stdout.write('Выберите размер поля: 1 - 5x5, 2 - 10x10, 3 - 15x15: ');
    String? input = stdin.readLineSync()?.trim();
    switch (input) {
      case '1':
        return 5;
      case '2':
        return 10;
      case '3':
        return 15;
      default:
        print('Неверный выбор! Попробуйте снова.');
    }
  }
}

// Создание флота в зависимости от размера поля
List<Ship> getFleet(int size) {
  switch (size) {
    case 5:
      return [
        Ship('Destroyer', 3),
        Ship('Cruiser', 2),
        Ship('Sub', 1),
        Ship('Sub', 1),
      ];
    case 15:
      return [
        Ship('Carrier', 5),
        Ship('Carrier', 5),
        Ship('Battleship', 4),
        Ship('Battleship', 4),
        Ship('Battleship', 4),
        Ship('Destroyer', 3),
        Ship('Destroyer', 3),
        Ship('Destroyer', 3),
        Ship('Destroyer', 3),
        Ship('Cruiser', 2),
        Ship('Cruiser', 2),
        Ship('Cruiser', 2),
        Ship('Cruiser', 2),
        Ship('Cruiser', 2),
        Ship('Sub', 1),
        Ship('Sub', 1),
        Ship('Sub', 1),
        Ship('Sub', 1),
        Ship('Sub', 1),
        Ship('Sub', 1),
      ];
    default:
      return [
        Ship('Carrier', 4),
        Ship('Battleship', 3),
        Ship('Battleship', 3),
        Ship('Destroyer', 2),
        Ship('Destroyer', 2),
        Ship('Destroyer', 2),
        Ship('Sub', 1),
        Ship('Sub', 1),
        Ship('Sub', 1),
        Ship('Sub', 1),
      ];
  }
}

// Выбор режима игры
bool getGameMode() {
  while (true) {
    stdout.write('Режим: 1 - PvP, 2 - PvE (против бота): ');
    String? input = stdin.readLineSync()?.trim();
    if (input == '1' || input == '2') {
      return input == '2';
    }
    print('Неверный выбор! Попробуйте снова.');
  }
}

// Размещение кораблей игроком
void placeShips(Board board, List<Ship> fleet, bool isBot) {
  for (var ship in fleet) {
    while (true) {
      board.printBoard(true);
      stdout.write('Разместите ${ship.name} (размер ${ship.size}). Ряд (1-${board.size}): ');
      int x = (int.tryParse(stdin.readLineSync()?.trim() ?? '') ?? 0) - 1;
      stdout.write('Столбец (1-${board.size}): ');
      int y = (int.tryParse(stdin.readLineSync()?.trim() ?? '') ?? 0) - 1;
      stdout.write('Горизонтально? (y/n): ');
      bool hor = (stdin.readLineSync()?.trim().toLowerCase() ?? 'y') == 'y';
      if (board.placeShip(ship, x, y, hor)) {
        break;
      }
      print('Неверное размещение! Попробуйте снова.');
    }
  }
}

// Размещение кораблей ботом
void placeShipsBot(Board board, List<Ship> fleet) {
  final rand = Random();
  for (var ship in fleet) {
    while (true) {
      int x = rand.nextInt(board.size);
      int y = rand.nextInt(board.size);
      bool hor = rand.nextBool();
      if (board.placeShip(ship, x, y, hor)) {
        break;
      }
    }
  }
}

// Ход игрока
void playerAttack(Board opponent, String player) {
  while (true) {
    stdout.write('$player, атакуйте. Ряд (1-${opponent.size}): ');
    int x = (int.tryParse(stdin.readLineSync()?.trim() ?? '') ?? 0) - 1;
    stdout.write('Столбец (1-${opponent.size}): ');
    int y = (int.tryParse(stdin.readLineSync()?.trim() ?? '') ?? 0) - 1;
    String result = opponent.attack(x, y);
    if (result == 'I') {
      print('Вне поля! Попробуйте снова.');
    } else if (result == 'A') {
      print('Уже атаковано! Попробуйте снова.');
    } else {
      print(result == 'H' ? 'Попадание!' : 'Промах!');
      break;
    }
  }
}

// Ход бота
void botAttack(Board opponent) {
  final rand = Random();
  while (true) {
    int x = rand.nextInt(opponent.size);
    int y = rand.nextInt(opponent.size);
    String result = opponent.attack(x, y);
    if (result != 'A') {
      print('Бот атаковал: ${result == 'H' ? 'Попадание!' : 'Промах!'}');
      break;
    }
  }
}

// Очистка консоли
void clearConsole() {
  stdout.write('\x1B[2J\x1B[0;0H');
}

// Вопрос о новой игре
bool askPlayAgain() {
  stdout.write('Новая игра? (y/n): ');
  return (stdin.readLineSync()?.trim().toLowerCase() ?? 'n') == 'y';
}
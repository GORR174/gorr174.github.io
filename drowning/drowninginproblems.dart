import 'dart:html';
import 'dart:async';

DateTime now = new DateTime.now();

class Problem {
  String id;
  String description;
  Duration duration;
  List<String> solvesProblems = new List<String>();
  List<String> causesProblems = new List<String>();
  Element element;
  bool active = false;
  bool solving = false;
  DateTime solveStart;
  bool solvesAll = false;
  bool removesAll = false;
  Map<String, int> awards = {};
  Map<String, int> costs = {};
  bool solvable = true;
  List<String> requires = [];
  
  Problem(this.id, this.description, this.duration) {
    problems[id] = this;
  }
  
  void solves(String id) => solvesProblems.add(id);
  void causes(String id) => causesProblems.insert(0, id);
  
  void insertAfter(Element element) {
    element.insertAdjacentHtml("afterend", "<div id='$id'></div>");
    setElement(querySelector("#$id"));
  }

  void insertIn(Element element) {
    element.innerHtml="<div id='$id'></div>";
    setElement(querySelector("#$id"));
  }
  
  void setElement(Element element) {
    this.element = element;
    active = true;
    solving = false;
    activeProblems.add(this);
    equipmentUpdated();
  }
  
  void equipmentUpdated() {
    bool fitsRequirements = true;
    requires.forEach((id){
      if (!equipment.containsKey(id)) {
        fitsRequirements = false;
      }
    });
    
    String costString = "";
    if (costs.isNotEmpty) {
      costs.keys.forEach((id){
        if (costString.isNotEmpty) costString+=" ";
        if (costs[id]==1) {
          costString+="-$id";
        } else {
          costString+="-${costs[id]} $id";
        }
      });
      costString=" <span class='cost'>$costString</span>";
    }
    String awardString = "";
    if (awards.isNotEmpty) {
      awards.keys.forEach((id){
        if (awardString.isNotEmpty) awardString+=" ";
        if (awards[id]==1) {
          awardString+="+$id";
        } else {
          awardString+="+${awards[id]} $id";
        }
      });
      awardString=" <span class='award'>$awardString</span>";
    }

    if (canAfford()) {
      this.element.innerHtml = "$description <a href='#' id='${id}_solve'>Решить</a>.$costString$awardString";
      querySelector("#${id}_solve").onClick.listen((t)=>solve());
    } else {
      this.element.innerHtml = "$description [Не можешь себе позволить]$costString$awardString";
    }
    
    if (!fitsRequirements) {
      remove();
    }
  }
  
  void require(String id) {
    requires.add(id);
  }
  
  void solve() {
    if (!canAfford()) return;
    
    if (costs.isNotEmpty) {
      costs.keys.forEach((id) {
        equipment[id]-=costs[id];
        if (equipment[id]==0) equipment.remove(id);
      });
      updateEquipment();
    }
    
    solving = true;
    solveStart = now;
    tick();
  }
  
  bool canAfford() {
    bool afford = true;
    if (costs.isNotEmpty) {
      costs.keys.forEach((id){
        if (!equipment.containsKey(id)) afford = false;
        else if (equipment[id]<costs[id]) afford = false;
      });
    }
    return afford;
  }
  
  void tick() {
    if (!solving) return;
    
    
    Duration elapsedTime = now.difference(solveStart);
    double progress = elapsedTime.inMilliseconds/duration.inMilliseconds;
    if (progress>1.0) {
      progress = 1.0;
      solved();
    } else {
      element.innerHtml = "$description [${(progress*100).toStringAsFixed(2)}%]";
    }
  }
  
  void solved() {
    solving = false;
    if (removesAll) {
      equipment.clear();
      equipment["Надежда"] = 1;
      equipment["Тело"] = 1;
    }
    if (awards.isNotEmpty) {
      awards.keys.forEach((id){
        if (!equipment.containsKey(id)) equipment[id]=0;
        equipment[id]+=awards[id];
      });
    }
    updateEquipment();
    solvesProblems.forEach((id){
      if (problems[id].active) {
        problems[id].remove();
      }
    });
    if (solvesAll) {
      new List<Problem>.from(activeProblems).forEach((p) {
        if (p!=this && p.active) {
          p.remove();
        }
      });
    }
    causesProblems.forEach((id){
      if (!problems[id].active) {
        problems[id].insertAfter(element);
      }
    });
    
    if (solvable) remove();
  }
  
  void award(String id, [int quantity = 1]) {
    if (!awards.containsKey(id)) awards[id] = 0;
    awards[id]+=quantity;
  }

  void cost(String id, [int quantity = 1]) {
    if (!costs.containsKey(id)) costs[id] = 0;
    costs[id]+=quantity;
  }
  
  void remove() {
    activeProblems.remove(this);
    element.remove();
    active = false;
    solving = false;
  }
}

Map<String, Problem> problems = {};
Map<String, int> equipment = {};

List<Problem> activeProblems = new List<Problem>();

void main() {
  new Problem("start", "Здесь ничего.", new Duration(seconds:10))..causes("age0");
  new Problem("age0", "Тебя нет.", new Duration(seconds:5))..causes("age1")..award("Надежда");
  new Problem("age1", "Ты начинаешь появляться.", new Duration(seconds:3))..causes("age2")..award("Тело");
  new Problem("age2", "Ты есть.", new Duration(seconds:3))..causes("age3")..award("Жизнь")..causes("learn");
  new Problem("age3", "Ты родился.", new Duration(seconds:3))..causes("age4")..award("Любовь")..causes("play");
  new Problem("age4", "Ты - младенец.", new Duration(seconds:3))..causes("age5")..award("Невинность")..causes("meetfriend")..cost("Знания", 8);
  new Problem("age5", "Ты - дитя.", new Duration(seconds:3))..causes("age6")..award("Верность")..cost("Опыт", 4)..causes("meetlove")..causes("findwork");
  new Problem("age6", "Ты - подросток.", new Duration(seconds:3))..causes("age7")..cost("Разбитое Сердце", 2)..causes("create")..causes("morestuff");
  new Problem("age7", "Ты - взрослый.", new Duration(seconds:3))..causes("age8")..cost("Верность")..cost("Разрушенные Мечты", 1)..causes("changeworld");
  new Problem("age8", "Ты встревоженный.", new Duration(seconds:3))..causes("age9")..cost("Невинность")..solves("meetfriend")..solves("play")..solves("meetlove")..cost("Потерянные Амбиции");
  new Problem("age9", "Ты разбит.", new Duration(seconds:3))..causes("age10")..cost("Любовь")..solves("create")..solves("meetlove")..solves("makelove")..solves("friend")..solves("learn")..cost("Воспоминания", 10);
  new Problem("age10", "Ты начинаешь принимать это.", new Duration(milliseconds:800))..causes("age11")..cost("Жизнь")..solvesAll=true..removesAll=true;
  new Problem("age11", "Ты умер.", new Duration(seconds:60))..causes("age12")..cost("Тело");
  new Problem("age12", "Ты забыт.", new Duration(seconds:60*5))..causes("age13")..cost("Надежда");
  new Problem("age13", "Здесь ничего.", new Duration(seconds:60*10));
  
  new Problem("play", "Тебе надо играть.", new Duration(seconds:2))..solvable=false..award("Воспоминания");
  new Problem("findwork", "Тебе нужно найти работу.", new Duration(seconds:8))..award("Работа")..causes("work");
  new Problem("work", "Тебе нужно идти на работу.", new Duration(seconds:4))..award("Деньги")..award("Стресс")..solvable=false..causes("relax")..causes("betterjob")..require("Работа");
  new Problem("relax", "Тебе нужно расслабиться.", new Duration(seconds:8))..solvable=false..cost("Стресс")..require("Стресс");
  new Problem("meetfriend", "Тебе нужно больше друзей.", new Duration(seconds:8))..award("Друг")..solvable=false..causes("friend");
  new Problem("friend", "Тебе нужно увидеть друга.", new Duration(seconds:4))..solvable=false..award("Воспоминания")..causes("moveon")..require("Друг");
  new Problem("moveon", "Тебе нужно двигаться дальше.", new Duration(seconds:2))..cost("Друг")..award("Опыт");
  new Problem("betterjob", "Тебе нужна лучшая работа.", new Duration(seconds:6))..cost("Знания", 4)..solvable=false..require("Работа")..award("Уважение");
  new Problem("learn", "Тебе нужно учиться.", new Duration(seconds:2))..award("Знания")..solvable=false;
  new Problem("meetlove", "Тебе нужно влюбиться.", new Duration(seconds:6))..causes("makelove")..award("Влюблённый");
  new Problem("makelove", "Тебе нужно добиться взаимности.", new Duration(seconds:4))..solvable=false..award("Воспоминания")..causes("loselover")..require("Влюблённый");
  new Problem("loselover", "Тебе нужно принять разлуку.", new Duration(seconds:2))..cost("Влюблённый")..award("Разбитое Сердце")..causes("meetlove")..solves("makelove")..award("Опыт");
  new Problem("create", "Тебе нужно создавать.", new Duration(seconds:5))..solvable=false..award("Проект")..causes("fail")..cost("Деньги", 4);
  new Problem("fail", "Тебе нужно терпеть неудачу.", new Duration(seconds:5))..cost("Проект")..award("Разрушенные Мечты")..award("Воспоминания");
  new Problem("changeworld", "Тебе нужно трудиться усерднее.", new Duration(seconds:10))..award("Потерянные Амбиции")..cost("Уважение",  5)..cost("Имущество", 10);
  new Problem("morestuff", "Тебе нужно больше имущества.", new Duration(seconds:2))..award("Имущество")..cost("Деньги")..solvable=false;
  
  problems["start"].insertIn(querySelector("#problems"));
  new Timer.periodic(const Duration(milliseconds: 16), (t)=>tick());
}

void updateEquipment() {
  if (equipment.isEmpty) {
    querySelector("#equipment").innerHtml = "";
  } else {
    String inventoryList = "";
    equipment.keys.forEach((key){
      if (inventoryList.isNotEmpty) inventoryList+="<br>";
      if (equipment[key]==1) {
        inventoryList+="$key";
      } else {
        inventoryList+="${equipment[key]} $key";
      }
    });
    querySelector("#equipment").innerHtml = "У тебя есть:<br>$inventoryList";
  }
  new List<Problem>.from(activeProblems).forEach((e)=>e.equipmentUpdated());
}

void tick() {
  now = new DateTime.now();
  new List<Problem>.from(activeProblems).forEach((e)=>e.tick());
}

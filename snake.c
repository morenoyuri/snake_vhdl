#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <curses.h>
#include <termios.h>
#include <unistd.h>
#include <fcntl.h>

#define espaco 0
#define tamanhoInicial 3
#define comida -1

#define largura_mapa 11
#define altura_mapa 11

#define cima 0
#define direita 1
#define baixo 2
#define esquerda 3

#define teclaCima 65
#define teclaDireita 67
#define teclaBaixo 66
#define teclaEsquerda 68

//Compilar utilizando -lcurses na linha de comando

int *mapa, tamanho;

//Declaracao de funcoes
void imprimeMapa();
void criaMapa();
void geraComida();
void cabecaAnda(int direcao);
void criaCobra();
void corpoAnda(int pedaco, int posicao);
int achaCabeca();
int defineDirecao(int tecla);

int main(){
	tamanho = tamanhoInicial;
	int direcao = defineDirecao(teclaDireita), tecla = teclaDireita;
	criaMapa();
	initscr();
	cbreak();
	noecho();
	do{
		clear();
		imprimeMapa();
		tecla = getch();
		direcao = defineDirecao(tecla);	
		cabecaAnda(direcao);
		refresh();
	}while(1);
	getch();
	endwin();
    return 0;
}

void criaMapa(){
	mapa = malloc(sizeof(int) * (largura_mapa * altura_mapa - 1));
	for(int i = 0; i < largura_mapa * altura_mapa-1; i++){
		mapa[i] = 0;
	}
	criaCobra(tamanhoInicial);
	geraComida();
}

void geraComida(){
	//Gera numero aleatorio
	srand((unsigned)time(NULL));
	int lugarComida = rand() % (largura_mapa*altura_mapa-1);
	while(mapa[lugarComida] == 1)
		lugarComida = rand() % (largura_mapa*altura_mapa-1);
	if(mapa[lugarComida] == 0)
		mapa[lugarComida] = -1;
}

void imprimeMapa(){
	for(int i = 0; i < largura_mapa; i++)
		printw(" _ ");
	printw("\n");
	for(int i = 0; i < largura_mapa*altura_mapa-1; i++){
		if(i % largura_mapa == 0)
			printw("|");
		if(i % largura_mapa == 0 && i != 0)
			printw("\n");
        if(i % largura_mapa == 0 && i != 0)
			printw("|");
		if(mapa[i] == espaco)
			printw("   ");
		if(mapa[i] > espaco && mapa[i] != tamanho)
			printw(" o ");
		if(mapa[i] == comida)
			printw(" . ");
		if(mapa[i] == tamanho){
			printw(" c ");
		}
	}
	printw("   | \n");
	for(int i = 0; i < largura_mapa; i++)
		printw(" _ ");
}

void finalizaApp(){
	clear();
	printw("FIM DE JOGO!!!\n");
	getch();
	endwin();
	exit(0);
}

void cabecaAnda(int direcao){
	int posicao = achaCabeca(), comeu = 0, debug = 0;
	if(direcao == cima){
		posicao = posicao - largura_mapa;
		if(mapa[posicao] > 0 || posicao < 0){
			finalizaApp();
		}
	}
	if(direcao == direita){
		posicao = posicao + 1;
		if(mapa[posicao] > 0 || posicao % largura_mapa == 0){
			finalizaApp();
		}
	}
	if(direcao == baixo){
		posicao = posicao + largura_mapa;
		if(mapa[posicao] > 0 || posicao > largura_mapa*altura_mapa-1){
			finalizaApp();
		}
	}
	if(direcao == esquerda){
		if(mapa[posicao-1] > 0 || (posicao % largura_mapa) == 0){
			finalizaApp();
		}
		posicao = posicao - 1; 
	}
	if(mapa[posicao] == -1){
		tamanho++;
		comeu = 1;
	}
	if(comeu == 1) geraComida();
	mapa[posicao] = tamanho;
	if(comeu == 0){
		if(mapa[posicao-1] == tamanho && mapa[posicao-1] > 0)
			corpoAnda(tamanho, posicao-1);
		else{
			if(mapa[posicao+1] == tamanho && mapa[posicao+1] > 0)
				corpoAnda(tamanho, posicao+1);
			else{
				if(mapa[posicao+largura_mapa] == tamanho && mapa[posicao+largura_mapa] > 0)
					corpoAnda(tamanho, posicao+largura_mapa);
				else{
					if(mapa[posicao-largura_mapa] == tamanho && mapa[posicao-largura_mapa] > 0)
						corpoAnda(tamanho, posicao-largura_mapa);
				}
			}
		} 
		
	}
}

void corpoAnda(int pedaco, int posicao){
	if(pedaco > 0){
		if(mapa[posicao-1] == pedaco-1 && mapa[posicao-1] > 0)
			corpoAnda(pedaco-1, posicao-1);
		else {
			if(mapa[posicao+1] == pedaco -1 && mapa[posicao+1] > 0)
				corpoAnda(pedaco-1, posicao+1);
			else{
					if(mapa[posicao+largura_mapa] == pedaco -1 && mapa[posicao+largura_mapa] > 0)
						corpoAnda(pedaco-1, posicao+largura_mapa);
					else{
						if(mapa[posicao-largura_mapa] == pedaco -1 && mapa[posicao-largura_mapa] > 0)
							corpoAnda(pedaco-1, posicao-largura_mapa);
					}	
			}	
		}
		mapa[posicao]--;
	}
}

int achaCabeca(){
	for(int i = 0; i < altura_mapa*largura_mapa-1; i++){
		if(mapa[i] == tamanho){
			return i;
		}
	}
}

void criaCobra(){
	mapa[(largura_mapa*altura_mapa-1)/2] = tamanho;
	for(int i = 1; i < tamanho; i++){
		mapa[(largura_mapa*altura_mapa-1)/2 - i] = tamanho - i;
	}
}

int defineDirecao(int tecla){
	if(tecla == teclaBaixo)
		return baixo;
	if(tecla == teclaCima)
		return cima;
	if(tecla == teclaEsquerda)
		return esquerda; 
	if(tecla == teclaDireita)
		return direita;
}



import Visitor from "../visitor/Visitor.js";
import {Rango} from '../visitor/CST.js';
import { generateCaracteres } from "./utils.js";
import { CondicionalStrSencilla } from "./utils.js";

export default class Tokenizer extends Visitor {

    visitProducciones(node) {
		console.log('Producciones: ', node) 
        return node.expr.accept(this);
    }
	visitOpciones(node) {
		console.log('Opciones: ', node)
		return node.exprs.map(node => node.accept(this)).join('\n');
	}
	visitUnion(node) {
		console.log('Expresion: ', node)
		return node.exprs.map(node => node.accept(this)).join('\n');
	}
	visitExpresion(node) {
		console.log('Expresion: ', node)
		if (node.qty !== '*'){
			return node.expr.accept(this);
		}
		let condicional = CondicionalStrSencilla(node.expr);
		return `
		! * en literales
		ejecuta_ciclo = .true.
		start_cursor = cursor  
		allocate(character(len=0) :: lexeme_accumulated)  
		do while (ejecuta_ciclo)	
			if ( ${condicional} ) then
                cursor = cursor + ${node.expr.val.length}
                lexeme_accumulated = lexeme_accumulated // "${node.expr.val}"
            else
                ejecuta_ciclo = .false.
            end if
		end do
		if (len(lexeme_accumulated) > 0) then
			allocate(character(len=len(lexeme_accumulated)) :: lexeme)
			lexeme = lexeme_accumulated
        	return
    	end if
	`
		
	}
	
	visitString(node) {
		console.log('String: ', node)
		let condicional = CondicionalStrSencilla(node);

		return `
		if ( ${condicional} ) then
			allocate(character(len=${node.val.length}) :: lexeme)
			lexeme = input(cursor:cursor + ${node.val.length - 1})
			cursor = cursor + ${node.val.length}
			return
		end if
		`;
	}
	
	
	visitClase(node){
		console.log('Clase', node)
		return `
		i = cursor
		${generateCaracteres(
			node.chars.filter((node) => typeof node === 'string')
		)}
		${
			node.chars
				.filter((node)  => node instanceof Rango )
				.map((range) => range.accept(this))
				.join('\n')
		}
		`
	}

	visitRango(node){
		return `
		if (input(i:i) >= "${node.rangoInicial}" .and. input(i:i) <= "${node.rangoFinal}") then
			lexeme = input(cursor:i)
			cursor = i + 1
			return
		end if
			`;
	}

	
}

/*
 
Práctica de Swift
 
Nombre Alumno: Diógenes Marino Garrido
 
email: garrido.nito@gmail.com
 
Este programa incluye cinco ejemplos de uso para realizar pruebas de reservaciones de Hotel.
 
En el caso de la reservación # 5, la misma es rechazada por haber detectado el nombre de
un cliente que ya tenía registrada una reservación previa.
 
Los casos de reservaciones con un mismo ID no podrían producirse, puesto que el ID de la reserva
es generado por un contador de manera interna, según las especificacioes del programa.
 
También hay dos ejemplos de uso de cancelación de reservaciones.
 
En el primer caso, se canceló satisfactoriamente una de las reservaciones que se habían
realizado previamente (Específicamente la reserva que tenía el ID # 3).
 
En el segundo caso se intentó cancelar una reservación cuyo ID no existe (ID # 6) y se emitió alerta.
 
Luego se imprime un listado con todas las reservas actuales.
 
 */

import Cocoa

struct Client: Equatable {
    let name: String
    let age: Int
}

struct Reservation {
    let reservationId: Int
    let hotelName: String
    let clientList: [Client]
    let reservedDays: Int
    let price: Double
    let hasBreakfast: Bool
}

struct ReservationError: Error {
    enum ErrorCase {
        case reservationWithSameId
        case reservationForExistingClient(duplicateNames: [String]) // En caso de detectar clientes con reservas previas,
                                                                    // guardaríamos en este array los nombres de clientes duplicados
        case reservationNotFound
    }
    
    let errorCase: ErrorCase
    let duplicateNames: [String]
    
    init(errorCase: ErrorCase, duplicateNames: [String] = []) {
           self.errorCase = errorCase
           self.duplicateNames = duplicateNames
       }
}


class HotelReservationManager {
    
    var clientReservations: [String: Reservation] = [:]
    
    func checkForDuplicateClients(clientList: [Client]) -> (Bool, [String]) {
          var uniqueNames = Set<String>()
          // Aquí almacenaremos los nombres de los clientes para los cuales se está intentando crear una reserva.
          // Cada vez que se intente agregar un cliente al conjunto uniqueNames, el método insert del conjunto verificará
          // si ya existe el nombre en el conjunto antes de agregarlo, asegurando que sólo se almacenen nombres únicos.
        
          var duplicateNames: [String] = []
          // Este arreglo se llenaría durante la verificación de duplicados al intentar agregar una nueva reserva.
          // Si se encuentran nombres de clientes que ya tienen previamente una reserva, se añadirían a este arreglo
          // para mantener un registro de los nombres duplicados.
        
        for client in clientList {
                    if !uniqueNames.insert(client.name).inserted {
                        duplicateNames.append(client.name)
                    }
        }

        return (duplicateNames.isEmpty == false, duplicateNames)
    }
    
    /*
     Este diccionario se utiliza para almacenar las reservas realizadas, 
     donde cada reserva se vincula a un número entero único (el ID de la reserva).
     */
    var reservations: [Int: Reservation] = [:]
    var reservationIDCounter: Int = 1
    
        func addReservation(clientList: [Client], reservedDays: Int, hasBreakfast: Bool, hotelName: String) throws -> Reservation {
            let (hasDuplicates, duplicateNames) = checkForDuplicateClients(clientList: clientList)

            if hasDuplicates {
                throw ReservationError(errorCase: .reservationForExistingClient(duplicateNames: duplicateNames))
            }

            for client in clientList {
                if let existingReservation = clientReservations[client.name] {
                    throw ReservationError(errorCase: .reservationForExistingClient(duplicateNames: [client.name]))
                }
                clientReservations[client.name] = Reservation(reservationId: reservationIDCounter,
                                                              hotelName: hotelName,
                                                              clientList: clientList,
                                                              reservedDays: reservedDays,
                                                              price: calculatePrice(numberOfClients: clientList.count, reservedDays: reservedDays, hasBreakfast: hasBreakfast),
                                                              hasBreakfast: hasBreakfast)
            }
            
            let totalPrice = calculatePrice(numberOfClients: clientList.count, reservedDays: reservedDays, hasBreakfast: hasBreakfast)

            let newReservation = Reservation(
                reservationId: reservationIDCounter,
                hotelName: hotelName,
                clientList: clientList,
                reservedDays: reservedDays,
                price: totalPrice,
                hasBreakfast: hasBreakfast
            )

            reservations[newReservation.reservationId] = newReservation
            reservationIDCounter += 1

            return newReservation
        }

    func calculatePrice(numberOfClients: Int, reservedDays: Int, hasBreakfast: Bool) -> Double {
        var basePricePerClient = 20.0
        var total = Double(numberOfClients) * basePricePerClient * Double(reservedDays)
        
        if hasBreakfast {
            total *= 1.25 // Incremento del 25% si hay desayuno
        }
        return total
    }
    
    func cancelReservation(reservationId: Int) throws -> Int? {
        guard reservations[reservationId] != nil else {
            throw ReservationError(errorCase: .reservationNotFound)
        }
        
        /*
        Aquí eliminaríamos del diccionario el valor asociado a la clave reservationId, si existe.
        forKey: reservationId indica qué elemento eliminar del diccionario utilizando como referencia el valor de reservationId.
        Si no se encontró o no se eliminó ningún valor, canceledReservationId será nil.
         */
        let canceledReservationId = reservations.removeValue(forKey: reservationId)?.reservationId
        return canceledReservationId
    }
    
    var currentReservations: [Reservation] {
            return Array(reservations.values)
        }
        
}

//  AQUÍ PRESENTO SECUENCIALMENTE, CINCO EJEMPLOS DE USO PARA REALIZAR NUEVAS RESERVACIONES
//
//  UNO DE ESTOS CINCO EJEMPLOS ES UN INTENTO DE AÑADIR UNA RESERVA DUPLICADA (Ejemplo # 5)
/*
 Ejemplo de uso (1 de 5) - Para añadir primera reservación
*/
var reservationManagement = HotelReservationManager()

var clients: [Client] = []
clients.append(Client(name: "Camilo Blanes", age: 30))
clients.append(Client(name: "Lolita Flores", age: 28))

do {
    let reservation = try reservationManagement.addReservation(clientList: clients, reservedDays: 3, hasBreakfast: true, hotelName: "Hotel Lina")
    print("Reserva agregada satisfactoriamente:")
    print(reservation)
    print(" ")
} catch let error as ReservationError {
    switch error.errorCase {
    case .reservationForExistingClient(let duplicateNames):
        print("Error: Se ha detectado una reserva con al menos un cliente duplicado.")
        print("Clientes duplicados encontrados: \(duplicateNames)")
        print(" ")
    default:
        print("Error al agregar la reserva: \(error)")
    }
} catch {
    print("Error desconocido: \(error)")
}

/*
 Ejemplo de uso (2 de 5) - Para añadir segunda reservación
*/
clients.removeAll() // Reinicializa el contenido del array "clients" que contiene los nombres de los clientes de una reservación

clients.append(Client(name: "Julio Iglesias", age: 52))
clients.append(Client(name: "Ana Belén", age: 45))

do {
    let reservation = try reservationManagement.addReservation(clientList: clients, reservedDays: 5, hasBreakfast: false, hotelName: "Hotel Jaragua")
    print("Reserva agregada satisfactoriamente:")
    print(reservation)
    print(" ")

} catch let error as ReservationError {
    switch error.errorCase {
    case .reservationForExistingClient(let duplicateNames):
        print("Error: Se ha detectado una reserva con al menos un cliente duplicado.")
        print("Clientes duplicados encontrados: \(duplicateNames)")
        print(" ")
    default:
        print("Error al agregar la reserva: \(error)")
    }
} catch {
    print("Error desconocido: \(error)")
}

/*
 Ejemplo de uso (3 de 5) - Para añadir tercera reservación
*/
clients.removeAll() // Reinicializa el contenido del array "clients" que contiene los nombres de los clientes de una reservación

clients.append(Client(name: "Rosalía Vila", age: 25))
clients.append(Client(name: "José Luis Perales", age: 27))

do {
    let reservation = try reservationManagement.addReservation(clientList: clients, reservedDays: 5, hasBreakfast: false, hotelName: "Hotel Jaragua")
    print("Reserva agregada satisfactoriamente:")
    print(reservation)
    print(" ")
} catch let error as ReservationError {
    switch error.errorCase {
    case .reservationForExistingClient(let duplicateNames):
        print("Error: Se ha detectado una reserva con al menos un cliente duplicado.")
        print("Clientes duplicados encontrados: \(duplicateNames)")
        print(" ")
    default:
        print("Error al agregar la reserva: \(error)")
    }
} catch {
    print("Error desconocido: \(error)")
}

/*
 Ejemplo de uso (4 de 5) - Para añadir cuarta reservación
*/
clients.removeAll() // Reinicializa el contenido del array "clients" que contiene los nombres de los clientes de una reservación

clients.append(Client(name: "Ana Torroja", age: 25))
clients.append(Client(name: "Rafael Martos", age: 62))

do {
    let reservation = try reservationManagement.addReservation(clientList: clients, reservedDays: 5, hasBreakfast: false, hotelName: "Hotel Jaragua")
    print("Reserva agregada satisfactoriamente:")
    print(reservation)
    print(" ")
} catch let error as ReservationError {
    switch error.errorCase {
    case .reservationForExistingClient(let duplicateNames):
        print("Error: Se ha detectado una reserva con al menos un cliente duplicado.")
        print("Clientes duplicados encontrados: \(duplicateNames)")
        print(" ")
    default:
        print("Error al agregar la reserva: \(error)")
    }
} catch {
    print("Error desconocido: \(error)")
}

/*
 EJEMPLO de uso (5 de 5) -  INTENTANDO REALIZAR UNA RESERVA DUPLICADA:
 
 Aquí estamos intentando añadir otra reservación con Julio Iglesias y Ana Torroja, quienes se detectarían como DUPLICADOS
 En este caso, la función detecta que Julio Iglesias ya tiene una reservación previa y lo mismo sucede en el caso de
 Ana Torroja también ya tenía otra reservación aparte.  Por lo tanto, se emite alerta y NO se realiza esta reservación.
 
 La duplicidad solamente podría ocurrir con nombres de clientes, ya que con el ID de la reserva no podría darse, puesto que
 el ID de la reservación es generado internamente por la función addReservation mediante un contador.
*/

clients.removeAll() // Reinicializa el contenido del array "clients" que contiene los nombres de los clientes de una reservación
clients.append(Client(name: "Julio Iglesias", age: 52))
clients.append(Client(name: "Ana Torroja", age: 45))

do {
    let reservation = try reservationManagement.addReservation(clientList: clients, reservedDays: 5, hasBreakfast: false, hotelName: "Hotel Jaragua")
    print("Reserva agregada satisfactoriamente:")
    print(reservation)
    print(" ")
} catch let error as ReservationError {
    switch error.errorCase {
    case .reservationForExistingClient(let duplicateNames):
        print("Error: Se ha detectado una reserva con al menos un cliente duplicado.")
        print("Clientes duplicados encontrados: \(duplicateNames)")
        print(" ")
    default:
        print("Error al agregar la reserva: \(error)")
    }
} catch {
    print("Error desconocido: \(error)")
}


/*
 Ejemplo de uso - CANCELANDO RESERVACIÓN cuyo ID es el # 3 (Reserva de Rosalía Vila y José Luis Perales).
 En este caso la reservación se cancela satisfactoriamente.
*/
var queryId = 3

do {
    if let canceledId = try reservationManagement.cancelReservation(reservationId: queryId) {
        print("RESERVACIÓN CANCELADA con ID # : \(canceledId)")
        print(" ")
    }
} catch let error as ReservationError {
    switch error.errorCase {
    case .reservationNotFound:
        print("ERROR: La reservación con ID \(queryId) NO EXISTE")
        print(" ")
    default:
        print("Error al cancelar la reserva: \(error)")
    }
}

/*
 Ejemplo de uso - CANCELANDO RESERVACIÓN cuyo ID es una reserva que NO EXISTE
 En este caso, se emite alerta indicando que el ID de proporcionado ( ID # 6 ) NO existe.
*/
queryId = 6

do {
    if let canceledId = try reservationManagement.cancelReservation(reservationId: queryId) {
        print("RESERVACIÓN CANCELADA con ID # : \(canceledId)")
        print(" ")
    }
} catch let error as ReservationError {
    switch error.errorCase {
    case .reservationNotFound:
        print("ERROR: La reservación con ID \(queryId) NO EXISTE")
        print(" ")
    default:
        print("Error al cancelar la reserva: \(error)")
    }
}


/*
 LISTADO DE TODAS LAS RESERVAS ACUTALES
 
 Aquí imprimos un listado de todas las reservas que fueron realizadas previamente en los ejemplos de uso previos.
 */
let allReservations = reservationManagement.currentReservations

print("LISTADO DE TODAS LAS RESERVAS ACTUALES")

for reservation in allReservations {
    print("Número de Reservación: \(reservation.reservationId)")
    print("Hotel : \(reservation.hotelName)")
    print("Nombres :")
    for client in reservation.clientList {
        print("  - \(client.name)")
    }
    print("Días Reservados: \(reservation.reservedDays)")
    print("Precio: \(reservation.price)")
    print("Desayuno Incluido: \(reservation.hasBreakfast)")
    print("")
    print()
}

// Funciones de Test

func testAddReservation() {
    let reservationManager = HotelReservationManager()

    let clients1 = [Client(name: "José Domínguez", age: 30), Client(name: "María Torres", age: 28)]

    do {
        let reservation1 = try reservationManager.addReservation(clientList: clients1, reservedDays: 3, hasBreakfast: true, hotelName: "Hotel Lina")

        // Intentar agregar una reserva con el mismo ID
        do {
            let reservationWithSameId = try reservationManager.addReservation(clientList: [], reservedDays: 1, hasBreakfast: false, hotelName: "Hotel XYZ")
            assertionFailure("Se añadió una reserva con el mismo ID \(reservationWithSameId.reservationId)")
        } catch let error as ReservationError {
            switch error.errorCase {
            case .reservationWithSameId:
                print("Error: Ya existe una reserva con el mismo ID.")
            default:
                print("Error inesperado: \(error)")
            }
        } catch {
            print("Error desconocido: \(error)")
        }

        // Intentar agregar una reserva con nombres de clientes duplicados
        do {
            let clientsWithDuplicates = [Client(name: "José Domínguez", age: 30), Client(name: "María Torres", age: 28)]
            let reservationWithDuplicateNames = try reservationManager.addReservation(clientList: clientsWithDuplicates, reservedDays: 5, hasBreakfast: false, hotelName: "Hotel Continental")
            assertionFailure("Se añadió una reserva con clientes duplicados \(reservationWithDuplicateNames.clientList)")
        } catch let error as ReservationError {
            switch error.errorCase {
            case .reservationForExistingClient:
                print("Error: Se ha detectado una reserva con al menos un cliente duplicado.")
                print("Clientes duplicados encontrados: \(error.duplicateNames)")
            default:
                print("Error inesperado: \(error)")
            }
        } catch {
            print("Error desconocido: \(error)")
        }
    } catch let error as ReservationError {
        // Manejar el error si ocurre al agregar la primera reserva (clients1)
        print("Error al agregar la primera reserva: \(error)")
    } catch {
        print("Error desconocido al agregar la primera reserva: \(error)")
    }
}


func testCancelReservation() {
    let reservationManager = HotelReservationManager()

    // Agregar reservas aquí

    let initialReservationsCount = reservationManager.reservations.count
    let queryId = 4

    do {
        if let canceledId = try reservationManager.cancelReservation(reservationId: queryId) {
            print("Reservación Cancelada con ID: \(canceledId)")
        }
    } catch let error as ReservationError {
        switch error.errorCase {
        case .reservationNotFound:
            print("Error: La reservación con ID \(queryId) NO existe.")
        case .reservationWithSameId:
            print("Error: Ya existe una reserva con el mismo ID.")
        case .reservationForExistingClient:
            print("Error: El cliente ya tiene una reserva existente.")
        }
    } catch {
        print("Error desconocido: \(error)")
    }

    // Verificar que el número de reservas no cambió después de intentar cancelar una reserva inexistente
    assert(reservationManager.reservations.count == initialReservationsCount)
}


func testReservationPrice() {
    let reservationManager = HotelReservationManager()

    let clients1 = [Client(name: "José Domínguez", age: 30), Client(name: "María Torres", age: 28)]
    let clients2 = [Client(name: "Alicia Jiménez", age: 25), Client(name: "Juan Sánchez", age: 27)]

    do {
        let reservation1 = try reservationManager.addReservation(clientList: clients1, reservedDays: 3, hasBreakfast: true, hotelName: "Hotel Lina")
        let reservation2 = try reservationManager.addReservation(clientList: clients2, reservedDays: 3, hasBreakfast: true, hotelName: "Hotel Lina")

        // Verificar que los precios sean iguales para ambas reservas
        assert(reservation1.price == reservation2.price, "Los precios de las reservas son diferentes")
        print("Los precios de las reservas son iguales: \(reservation1.price)")

    } catch let error {
        print("Error al agregar la reserva: \(error)")
    }
}

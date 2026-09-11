import 'package:uuid/uuid.dart';

import '../../../core/models/backpack.dart';

List<Backpack> seedBackpacks() {
  const uuid = Uuid();
  return [
    Backpack(
      id: uuid.v4(),
      name: 'TrailPro 40L',
      brand: 'AndesPack',
      price: 1299,
      description:
          'Mochila de senderismo 40L, resistente al agua, espalda ventilada.',
      category: 'senderismo',
      stock: 5,
    ),
    Backpack(
      id: uuid.v4(),
      name: 'Urban Slim 20L',
      brand: 'CiudadBag',
      price: 749,
      description: 'Mochila urbana antirrobo con compartimento para laptop 15".',
      category: 'urbana',
      stock: 12,
    ),
    Backpack(
      id: uuid.v4(),
      name: 'Kids Dino 12L',
      brand: 'PequeTrek',
      price: 399,
      description: 'Mochila infantil ligera con reflectores y diseño dinosaurio.',
      category: 'infantil',
      stock: 8,
    ),
    Backpack(
      id: uuid.v4(),
      name: 'CargoMax 55L',
      brand: 'AndesPack',
      price: 1899,
      description: 'Mochila de viaje con ruedas opcionales y candado TSA.',
      category: 'viaje',
      stock: 3,
    ),
    Backpack(
      id: uuid.v4(),
      name: 'GymFlex 25L',
      brand: 'FitCarry',
      price: 599,
      description: 'Compartimento húmedo, porta zapatos y correa de pecho.',
      category: 'deportiva',
      stock: 10,
    ),
  ];
}

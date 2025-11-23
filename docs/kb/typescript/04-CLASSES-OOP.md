---
id: typescript-04-classes-oop
topic: typescript
file_role: detailed
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [javascript, typescript-basics]
related_topics: ['javascript', 'nextjs', 'react']
embedding_keywords: [typescript]
last_reviewed: 2025-11-13
---

# TypeScript Classes & OOP

**Part 4 of 11 - The TypeScript Knowledge Base**

## Quick Reference

This guide covers:
- Class definitions and instantiation
- Inheritance and polymorphism
- Access modifiers (public, protected, private)
- Static and readonly properties
- Constructors and initialization
- Method overriding

## Class Basics

```typescript
// Basic class
class Animal {
 name: string;
 age: number;

 constructor(name: string, age: number) {
 this.name = name;
 this.age = age;
 }

 describe: string {
 return `${this.name} is ${this.age} years old`;
 }
}

const dog = new Animal("Rex", 3);
console.log(dog.describe); // "Rex is 3 years old"
```

## Inheritance

```typescript
// Class inheritance
class Dog extends Animal {
 breed: string;

 constructor(name: string, age: number, breed: string) {
 super(name, age);
 this.breed = breed;
 }

 override describe: string {
 return `${super.describe} and is a ${this.breed}`;
 }

 bark: void {
 console.log("Woof!");
 }
}

const dog = new Dog("Rex", 3, "Labrador");
console.log(dog.describe); // "Rex is 3 years old and is a Labrador"
```

## Access Modifiers

```typescript
class User {
 public id: number; // Accessible everywhere (default)
 protected role: string; // Accessible in class & subclasses
 private password: string; // Only in this class

 constructor(id: number, role: string, password: string) {
 this.id = id;
 this.role = role;
 this.password = password;
 }

 protected hasRole(targetRole: string): boolean {
 return this.role === targetRole;
 }

 private validatePassword(pw: string): boolean {
 return pw === this.password;
 }
}

class Admin extends User {
 constructor(id: number, password: string) {
 super(id, "admin", password);
 }

 canAccess: boolean {
 return this.hasRole("admin"); // ✓ Protected method
 // return this.validatePassword("x"); // ERROR: Private method
 }
}
```

## Property Shortcuts

```typescript
// Shorthand constructor
class Point {
 constructor(
 public x: number,
 public y: number,
 private z: number = 0
 ) {}
}

// Equivalent to:
class PointLong {
 public x: number;
 public y: number;
 private z: number;

 constructor(x: number, y: number, z: number = 0) {
 this.x = x;
 this.y = y;
 this.z = z;
 }
}
```

## Static Members

```typescript
class MathUtil {
 static readonly PI = 3.14159;
 static readonly E = 2.71828;

 static add(a: number, b: number): number {
 return a + b;
 }

 static getPI: number {
 return this.PI; // 'this' refers to class
 }
}

console.log(MathUtil.PI); // 3.14159
console.log(MathUtil.add(1, 2)); // 3
```

## Readonly Properties

```typescript
class Config {
 readonly apiUrl: string;
 readonly timeout: number = 5000;

 constructor(apiUrl: string) {
 this.apiUrl = apiUrl;
 }
}

const config = new Config("https://api.example.com");
// config.apiUrl = "new-url"; // ERROR: readonly
// config.timeout = 10000; // ERROR: readonly
```

## Getters & Setters

```typescript
class Temperature {
 private celsius: number;

 constructor(celsius: number) {
 this.celsius = celsius;
 }

 get fahrenheit: number {
 return (this.celsius * 9) / 5 + 32;
 }

 set fahrenheit(f: number) {
 this.celsius = ((f - 32) * 5) / 9;
 }
}

const temp = new Temperature(0);
console.log(temp.fahrenheit); // 32
temp.fahrenheit = 212;
console.log(temp.celsius); // 100
```

## Abstract Classes

```typescript
// Cannot be instantiated, only inherited
abstract class Shape {
 abstract area: number;

 describe: string {
 return `Area: ${this.area}`;
 }
}

class Circle extends Shape {
 constructor(private radius: number) {
 super;
 }

 area: number {
 return Math.PI * this.radius ** 2;
 }
}

// const shape = new Shape; // ERROR: abstract
const circle = new Circle(5);
console.log(circle.area); // ~78.5
```

## Interfaces with Classes

```typescript
interface Drawable {
 draw: void;
}

interface Serializable {
 toJSON: string;
}

class Document implements Drawable, Serializable {
 content: string;

 constructor(content: string) {
 this.content = content;
 }

 draw: void {
 console.log(this.content);
 }

 toJSON: string {
 return JSON.stringify({ content: this.content });
 }
}

const doc = new Document("Hello");
doc.draw; // "Hello"
console.log(doc.toJSON); // '{"content":"Hello"}'
```

## Best Practices

✅ **DO**:
- Use `private` by default
- Only use `public` when necessary
- Use `protected` for extensibility
- Mark unchanging properties `readonly`
- Use abstract classes for contracts

❌ **DON'T**:
- Expose implementation details publicly
- Use `any` in class properties
- Create overly complex hierarchies
- Mix static and instance logic

---

**Next**: [05-GENERICS.md](./05-GENERICS.md) - Generics deep dive

**Last Updated**: November 8, 2025

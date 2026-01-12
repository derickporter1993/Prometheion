import { faker } from '@faker-js/faker';
import type { FakeStrategy } from '@platform/types';

type FakeGenerator = FakeStrategy['generator'];

/**
 * Fake strategy: Generates realistic fake data using Faker
 * Optionally deterministic based on input seed
 */
export function fake(
  value: string | null | undefined,
  options: Omit<FakeStrategy, 'type'> & { deterministic?: boolean }
): string {
  // Set locale if specified
  if (options.locale) {
    faker.setLocale(options.locale as Parameters<typeof faker.setLocale>[0]);
  }

  // If deterministic, seed faker with hash of original value
  if (options.deterministic && value) {
    faker.seed(hashCode(value));
  }

  return generateFakeValue(options.generator);
}

function generateFakeValue(generator: FakeGenerator): string {
  switch (generator) {
    case 'name':
      return faker.person.fullName();
    case 'first_name':
      return faker.person.firstName();
    case 'last_name':
      return faker.person.lastName();
    case 'email':
      return faker.internet.email();
    case 'phone':
      return faker.phone.number();
    case 'address':
      return faker.location.streetAddress();
    case 'city':
      return faker.location.city();
    case 'state':
      return faker.location.state();
    case 'zip':
      return faker.location.zipCode();
    case 'country':
      return faker.location.country();
    case 'company':
      return faker.company.name();
    case 'ssn':
      // Generate SSN-like pattern: XXX-XX-XXXX
      return `${faker.string.numeric(3)}-${faker.string.numeric(2)}-${faker.string.numeric(4)}`;
    case 'date':
      return faker.date.past().toISOString().split('T')[0] ?? '';
    case 'number':
      return faker.number.int({ min: 1, max: 999999 }).toString();
    case 'text':
      return faker.lorem.sentence();
    default:
      return faker.lorem.word();
  }
}

/**
 * Generate deterministic fake value based on original
 * Same input always produces same fake output
 */
export function fakeDeterministic(
  value: string | null | undefined,
  options: Omit<FakeStrategy, 'type'>
): string {
  return fake(value, { ...options, deterministic: true });
}

/**
 * Simple hash code for seeding
 */
function hashCode(str: string): number {
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    const char = str.charCodeAt(i);
    hash = (hash << 5) - hash + char;
    hash = hash & hash; // Convert to 32-bit integer
  }
  return Math.abs(hash);
}

module.exports = {
	testEnvironment: 'node',
	verbose: true,
	roots: ['<rootDir>/tests'],
	transform: {
		'^.+\\.(ts|tsx)$': [
			'ts-jest',
			{ tsconfig: { target: 'ES2020' } }
		]
	},
	moduleFileExtensions: ['ts', 'js', 'json']
};
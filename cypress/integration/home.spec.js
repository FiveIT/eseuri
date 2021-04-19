/// <reference types="cypress" />

describe('Home', () => {
  it('should have "Eseuri." as title', () => {
    cy.visit('/').get('h1').contains('Eseuri.')
  })
})

/// <reference types="cypress" />

describe('Home', () => {
  it('should have "Cat Facts" as title', () => {
    cy.visit('/').get('h1').contains('Cat facts')
  })
})

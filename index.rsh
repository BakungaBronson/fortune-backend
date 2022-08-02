'reach 0.1';

// Write three fortunes.
const [ isFortune, FORTUNE1, FORTUNE2, FORTUNE3 ] = makeEnum(3);

// Shared functions
const sharedFunctions = {
  showFortune: Fun([UInt], Null),
}


export const main = Reach.App(() => {
  const A = Participant('Alice', {
    ...sharedFunctions,
    // Specify Alice's interact interface here
    // Alice pays the contract
    payContract: Fun([], UInt),
    // Alice decides if she accepts the fortune then Bob accepts payment (two possible decisions: true or false)
    acceptFortune: Fun([UInt], Bool),
  });
  const B = Participant('Bob', {
    ...sharedFunctions,
    // Specify Bob's interact interface here
    getFortune: Fun([], UInt),
  });
  init();
  // The first one to publish deploys the contract
  A.only(() => {
    const funds = declassify(interact.payContract());
  })
  A.publish(funds).pay(funds);
  commit();
  // The second one to publish always attaches
  B.publish();
  // write your program here

  var [decision, fortune] = [false, 0];

  invariant(balance() == funds);

  while(decision == false){
    commit();

    B.only(() => {
      const newFortune = declassify(interact.getFortune());
      check(isFortune(newFortune) == true);
    });
    B.publish(newFortune);
    commit();

    each([A, B], () => {
      interact.showFortune(newFortune);
    });

    A.only(() => {
      const accepted = declassify(interact.acceptFortune(newFortune));
    });
    A.publish(accepted);

    decision = accepted;
    continue;
  }
  // Repeat until Alice accepts fortune

  const [ forAlice, forBob ] = decision == true ? [ 0, 1 ] : [ 1, 0 ];
  transfer(forAlice * funds).to(A);
  transfer(forBob * funds).to(B);
  commit();

  exit();
});
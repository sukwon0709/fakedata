# fakedata

This library is a port of Ruby's
[faker](https://github.com/stympy/faker). Note that it directly uses
the source data from that library, so the quality of fake data is
quite high!

# Usage Tutorial

## Generating address

``` shellsession
~/g/fakedata (master) $ stack ghci
λ> import Faker.Address
λ> address <- generate fullAddress
λ> address
"Suite 153 153 Langosh Way, East Antony, MI 15342-5123"
```

## Generating name

``` shellsession
λ> fullName <- generate name
λ> fullName
"Antony Langosh"
```

## Combining Fake datas

```haskell
{-#LANGUAGE RecordWildCards#-}

import Faker
import Faker.Name
import Faker.Address
import Data.Text

data Person = Person {
    personName :: Text,
    personAddress :: Text
} deriving (Show, Eq)

fakePerson :: Fake Person
fakePerson = do
    personName <- name
    personAddress <- fullAddress
    pure $ Person{..}

main :: IO ()
main = do
    person <- generate fakePerson
    print person
```

And on executing them:

```
$ stack name.hs
Person {personName = "Antony Langosh", personAddress = "Suite 599 599 Brakus Flat, South Mason, MT 59962-6876"}
```

You would have noticed in the above output that the name and address are the same as in the first and second REPL interaction we do. That's because in this library all the outputs are deterministic. If you want a different set of ouput, you have to modify the random generator output:

```
main :: IO ()
main = do
    gen <- newStdGen
    let settings = setRandomGen gen defaultFakerSettings
    person <- generateWithSettings settings fakePerson
    print person
```

And on executing the program, you will get a different output:

``` shellsession
Person {personName = "Ned Effertz Sr.", personAddress = "Suite 158 1580 Schulist Mall, Schulistburgh, NY 15804-3392"}
```

The above program can be even minimized like this:

``` haskell
main :: IO ()
main = do
    let settings = setNonDeterministic defaultFakerSettings
    person <- generateWithSettings settings fakePerson
    print person
```

# Comparision with other libraries

There are two other libraries in the Hackage providing fake data:

* [faker](https://hackage.haskell.org/package/faker-0.0.0.2)
* [fake](https://hackage.haskell.org/package/fake-0.1.1.1)

The problem (for me) with both the above libraries is that the library covers a very small amount of fake data source. I wanted to have an equivalent functionality with something like [faker](https://github.com/stympy/faker). Also most of the combinators in this packages has been inspired (read as taken) from `fake`.

import std.random;
import std.range;
import std.stdio;

enum uint npersons    = 4000000;
enum uint nfamilies   = 1000000;
enum uint nworkplaces = npersons/50;

alias FamilyId = uint;
alias WorkplaceId = uint;

uint infectedFamilies;
uint infectedWorkplaces;

struct Group {
    uint infectedCount;
    Person[] persons;
    alias persons this;

    void incInfected(ref uint infectedTotal) {
        if(infectedCount == 0) {
            infectedTotal++;
        }
        infectedCount++;
    }
}
Group[FamilyId] families;
Group[WorkplaceId] workplaces;

class Person {
    uint family, workplace;
    bool wasSick;
    this(uint _family, uint _workplace) {
        this.family = _family;
        this.workplace = _workplace;
        families[family] ~= this;
        workplaces[workplace] ~= this;
    }

    void setSick() {
        wasSick = true;
        families[family].incInfected(infectedFamilies);
        workplaces[workplace].incInfected(infectedWorkplaces);
    }
}

void simulate(uint iterations) {
    Person[] persons;
    persons.reserve(npersons);
    foreach(i; 0..npersons) {
        persons ~= new Person(uniform(0, nfamilies), uniform(0, nworkplaces));
    }

    auto patient0 = persons[0];
    patient0.setSick();
    Person[] newSick = [patient0];
    auto totalSick = 1;
    foreach(i; 0..iterations) {
        auto currentIterationSick = newSick[];
        newSick = [];

        writefln("#%s (%s new sick), total sick=%s, families=%s, workplaces=%s",
                 i, currentIterationSick.length, totalSick, infectedFamilies, infectedWorkplaces);

        if(currentIterationSick.length == 0) break;
        foreach(p; currentIterationSick) {
            static struct PGroup { double probability; Group* persons; }
            foreach(pgroup; only(PGroup(0.3, &families[p.family]),
                                 PGroup(0.02, &workplaces[p.workplace])))
            {
                // writefln("Checking group of %s folks with %s probability of infection",
                //          pgroup.persons.length, pgroup.probability);
                foreach(other; *pgroup.persons) {
                    if(other.wasSick) continue;
                    if(uniform(0.0, 1.0) <= pgroup.probability) {
                        other.setSick();
                        newSick ~= other;
                        totalSick++;
                    }
                }
            }
        }
    }
}

void main() {
    simulate(1000000);
}
